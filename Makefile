## Configuration
# Get the version as parameter
VERSION = 9.403
VERSION_EGW = 1.0
AUTOSCALING_ARGS = --BYOL 3kn396xknha6uumomjcubi57w --Hourly 9b24287dgv39qtltt9nqvp9kx
HA_ARGS = --BYOL 2xxxjwpanvt6wvbuy0bzrqed7 --Hourly 9xg6czodp2h82gs0tuc1sfhsn
DEVEL_OWNER := 159737981378

# set to 1 to use devel amis in region/ami map
DEVEL :=

## file sets
HA_REGIONMAP = tmp/HA_REGIONMAP.json
AUTOSCALING_REGIONMAP = tmp/AUTOSCALING_REGIONMAP.json
EGW_REGIONMAP = tmp/EGW_REGIONMAP.json
VERSIONDIR = templates/conversion/$(VERSION) templates/egw/$(VERSION_EGW)

TEMPLATES := $(addprefix templates/, $(patsubst %.json,%.template,$(notdir $(wildcard src/*.json))))
CONVERSION_TEMPLATES := $(addprefix templates/conversion/$(VERSION)/, $(patsubst %.json,%.template,$(notdir $(wildcard src/conversion/*.json))))
EGW_TEMPLATES := templates/egw/$(VERSION_EGW)/egw.template

## bins
BUNDLE_EXEC = bundle exec
FETCH_REGIONMAP = $(BUNDLE_EXEC) ./bin/fetch_regionmap
BUILD_TEMPLATE = $(BUNDLE_EXEC) ./bin/build_template
GENERATE_TYPES = $(BUNDLE_EXEC) ./bin/generate_type_map

all: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(EGW_REGIONMAP) $(VERSIONDIR) $(TEMPLATES) $(CONVERSION_TEMPLATES) $(EGW_TEMPLATES)

# Always rebuild region maps
ifeq ($(DEVEL),1)
# Only for development: using the newest amis
# We don't use capture groups in the regex, so the sort (for 'newest') is using the
# entire name string like axg9400_verdi-asg-9.375-20160216.2_64_ebs_byol
# Using verdi branch (axg*_verdi) for HA
$(HA_REGIONMAP): $(dir $(HA_REGIONMAP))
	$(BUNDLE_EXEC) ./bin/fetch_region_ami_map_dev --owner '$(DEVEL_OWNER)' \
            --key BYOL --regex '^axg\d+_verdi-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(GENERATE_TYPES) --in $@ --out $@

# Using aws branch (asg*_aws) for Autoscaling
$(AUTOSCALING_REGIONMAP): $(dir $(AUTOSCALING_REGIONMAP))
	$(BUNDLE_EXEC) ./bin/fetch_region_ami_map_dev --owner '$(DEVEL_OWNER)' \
	    --key BYOL --regex '^axg\d+_aws-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(GENERATE_TYPES) --in $@ --out $@

# Build EGW templates using aws branch
$(EGW_REGIONMAP): $(dir $(EGW_REGIONMAP))
	$(BUNDLE_EXEC) ./bin/fetch_region_ami_map_dev --owner '$(DEVEL_OWNER)' \
	   --key EGW --regex '^egw-\d+\.\d+\.\d+-\d+' > '$@'
	@$(GENERATE_TYPES) --in $@ --out $@
else
$(HA_REGIONMAP): tmp
	@echo Building HA regionmap
	@$(FETCH_REGIONMAP) $(HA_ARGS) --out $@
	@$(GENERATE_TYPES) --in $@ --out $@

$(AUTOSCALING_REGIONMAP): tmp
	@echo Building Autoscaling RegionMap
	@$(FETCH_REGIONMAP) $(AUTOSCALING_ARGS) --out $@
	@$(GENERATE_TYPES) --in $@ --out $@

# Build EGW templates using aws branch.
# TODO: Change to production script when we are publishing production templates.
$(EGW_REGIONMAP): $(dir $(EGW_REGIONMAP))
	$(BUNDLE_EXEC) ./bin/fetch_region_ami_map_dev --owner '$(DEVEL_OWNER)' \
	   --key EGW --regex '^egw-\d+\.\d+\.\d+-\d+' > '$@'
	@$(GENERATE_TYPES) --in $@ --out $@

endif

# Overwrite autoscaling target to use autoscaling region map
templates/autoscaling_waf.template: src/autoscaling_waf.json $(AUTOSCALING_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP) --out $@

templates/%.template: src/%.json $(HA_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP) --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/conversion/$(VERSION)/autoscaling.template: src/conversion/autoscaling.json $(AUTOSCALING_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP) --out $@

templates/conversion/$(VERSION)/%.template: src/conversion/%.json $(HA_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP) --out $@

# Create EGW templates from src directory.
templates/egw/$(VERSION_EGW)/%.template: src/egw/%.json $(EGW_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(EGW_REGIONMAP) --out $@

# Create new version directory, if previous doesn't exist
# Create symlinks
# Check if we already have symlink. If so then we delete it. As we create new one in next step.
# Also ignore any errors

$(VERSIONDIR):
	@echo Creating new conversion release directory
	@mkdir -p $@
	-@[ -e $(dir $@)current ] && rm $(dir $@)current
	@ln -s -r -s -f $@ $(dir $@)current

#tmp dir is not in git and empty. Must be created if it does not exist yet
tmp:
	@mkdir $@


.PHONY: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(EGW_REGIONMAP) $(VERSIONDIR)
