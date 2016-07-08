## Configuration
# UTM_VERSION = *_verdi branch version that has been deployed to aws
# The default here is only for convenience, and usually is passed with the
# jenkins build job or during execution
UTM_VERSION ?= 9.405
# EGW_VERSION = version of interface paramters (if they change in an
# incompatible way, the version updates also)
EGW_VERSION ?= 1.0
AUTOSCALING_ARGS = --BYOL 3kn396xknha6uumomjcubi57w --Hourly 9b24287dgv39qtltt9nqvp9kx
HA_ARGS = --BYOL 2xxxjwpanvt6wvbuy0bzrqed7 --Hourly 9xg6czodp2h82gs0tuc1sfhsn
EGW_ARGS = --EGW
DEVEL_OWNER := 159737981378

# set to 1 to use devel amis in region/ami map
DEVEL :=

## file sets
HA_REGIONMAP = tmp/HA_REGIONMAP.json
AUTOSCALING_REGIONMAP = tmp/AUTOSCALING_REGIONMAP.json
EGW_REGIONMAP = tmp/EGW_REGIONMAP.json
UTM_VERSION_DIR = templates/conversion/$(UTM_VERSION)
EGW_VERSION_DIR = templates/egw/$(EGW_VERSION)

TEMPLATES := $(addprefix templates/, $(patsubst %.json,%.template,$(notdir $(wildcard src/*.json))))
CONVERSION_TEMPLATES := $(addprefix templates/conversion/$(UTM_VERSION)/, $(patsubst %.json,%.template,$(notdir $(wildcard src/conversion/*.json))))
EGW_TEMPLATES := templates/egw/$(EGW_VERSION)/egw.template

## bins
BUNDLE_EXEC = bundle exec
CREATE_REGIONMAP = $(BUNDLE_EXEC) ./bin/create_regionmap
CREATE_REGIONMAP_DEV = $(BUNDLE_EXEC) ./bin/create_regionmap_dev
BUILD_TEMPLATE = $(BUNDLE_EXEC) ./bin/build_template
ADD_TYPES_TO_MAP = $(BUNDLE_EXEC) ./bin/add_types_to_map

all: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(UTM_VERSION_DIR) $(TEMPLATES) $(CONVERSION_TEMPLATES) egw_publish

egw_publish: $(EGW_REGIONMAP) $(EGW_VERSION_DIR) $(EGW_TEMPLATES)

# Always rebuild region maps
ifeq ($(DEVEL),1)
# Only for development: using the newest amis
# We don't use capture groups in the regex, so the sort (for 'newest') is using the
# entire name string like axg9400_verdi-asg-9.375-20160216.2_64_ebs_byol
# Using verdi branch (axg*_verdi) for HA
$(HA_REGIONMAP): $(dir $(HA_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(DEVEL_OWNER)' \
            --key BYOL --regex '^axg\d+_verdi-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(ADD_TYPES_TO_MAP) --in $@ --out $@

# Using aws branch (asg*_aws) for Autoscaling
$(AUTOSCALING_REGIONMAP): $(dir $(AUTOSCALING_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(DEVEL_OWNER)' \
	    --key BYOL --regex '^axg\d+_aws-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(ADD_TYPES_TO_MAP) --in $@ --out $@

# Build EGW templates using aws branch
$(EGW_REGIONMAP): $(dir $(EGW_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(DEVEL_OWNER)' \
	   --key EGW --regex '^egw-\d+\.\d+\.\d+-\d+' > '$@'
	@$(ADD_TYPES_TO_MAP) --in $@ --out $@
else
$(HA_REGIONMAP): tmp
	@echo Building HA regionmap
	@$(CREATE_REGIONMAP) $(HA_ARGS) --out $@
	@$(ADD_TYPES_TO_MAP) --in $@ --out $@

$(AUTOSCALING_REGIONMAP): tmp
	@echo Building Autoscaling RegionMap
	@$(CREATE_REGIONMAP) $(AUTOSCALING_ARGS) --out $@
	@$(ADD_TYPES_TO_MAP) --in $@ --out $@

$(EGW_REGIONMAP): tmp
	@echo Building EGW RegionMap
	@$(CREATE_REGIONMAP) $(EGW_ARGS) --out $@
	@$(ADD_TYPES_TO_MAP) --in $@ --out $@

endif

# Overwrite autoscaling target to use autoscaling region map
templates/autoscaling_waf.template: src/autoscaling_waf.json $(AUTOSCALING_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP) --out $@

templates/%.template: src/%.json $(HA_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP) --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/conversion/$(UTM_VERSION)/autoscaling.template: src/conversion/autoscaling.json $(AUTOSCALING_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP) --out $@

templates/conversion/$(UTM_VERSION)/%.template: src/conversion/%.json $(HA_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP) --out $@

# Create EGW templates from src directory.
templates/egw/$(EGW_VERSION)/%.template: src/egw/%.json $(EGW_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(EGW_REGIONMAP) --out $@

$(UTM_VERSION_DIR) $(EGW_VERSION_DIR):
	@echo Creating $@ directory
	@mkdir -p $@
	@echo Linking $(dir $@)current to $(shell basename $@)
	-@ln -sf $(shell basename $@) $(dir $@)current

#tmp dir is not in git and empty. Must be created if it does not exist yet
tmp:
	@mkdir $@

clean:
	rm -rf templates/conversion templates/egw templates/*.template

.PHONY: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(EGW_REGIONMAP) \
	$(UTM_VERSION_DIR) clean
