## Configuration
# UTM_VERSION = *_verdi branch version that has been deployed to aws
# The default here is only for convenience, and usually is passed with the
# jenkins build job or during execution
UTM_VERSION ?= 9.405
# EGW_VERSION = version of interface paramters (if they change in an
# incompatible way, the version updates also)
EGW_VERSION ?= 1.0

# devel AMI owner ID
AMI_OWNER := 159737981378
export AMI_OWNER
# GovCloud AMI owner ID
GOV_OWNER := 219379113529

export AWS_DEFAULT_REGION := us-east-1

# Args for create_regionmap
HA_ARGS = --BYOL 2xxxjwpanvt6wvbuy0bzrqed7 --Hourly 9xg6czodp2h82gs0tuc1sfhsn
AUTOSCALING_ARGS = --BYOL 3kn396xknha6uumomjcubi57w --Hourly 9b24287dgv39qtltt9nqvp9kx
EGW_ARGS = --EGW

# Args for instance type mappings
HA_TYPES_ARGS = --type HA
AUTOSCALING_TYPES_ARGS = --type AS
EGW_TYPES_ARGS = --type EGW

# set to 1 to use devel amis in region/ami map
DEVEL :=

## file sets
HA_REGIONMAP = tmp/HA_REGIONMAP.json
AUTOSCALING_REGIONMAP = tmp/AUTOSCALING_REGIONMAP.json
EGW_REGIONMAP = tmp/EGW_REGIONMAP.json
HA_REGIONMAP_GOV = tmp/HA_REGIONMAP_GOV.json
AUTOSCALING_REGIONMAP_GOV = tmp/AUTOSCALING_REGIONMAP_GOV.json
EGW_REGIONMAP_GOV = tmp/EGW_REGIONMAP_GOV.json
HA_REGIONMAP_COMBINED = tmp/HA_REGIONMAP_COMBINED.json
AUTOSCALING_REGIONMAP_COMBINED = tmp/AUTOSCALING_REGIONMAP_COMBINED.json
EGW_REGIONMAP_COMBINED = tmp/EGW_REGIONMAP_COMBINED.json
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

all: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) egw_publish $(UTM_VERSION_DIR) $(TEMPLATES) $(CONVERSION_TEMPLATES)

egw_publish: $(EGW_REGIONMAP) $(EGW_VERSION_DIR) $(EGW_TEMPLATES)

# use these three targets in separate calls to build combined Cloud/GovCloud templates
region_map_regular_cloud: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(EGW_REGIONMAP)
# remember to set GovCloud access credentials befor running this target!
# DEVEL_OWNER is changed to GovClooud owner ID
region_map_gov_cloud: AMI_OWNER = $(GOV_OWNER)
region_map_gov_cloud: AWS_DEFAULT_REGION = us-gov-west-1
region_map_gov_cloud: $(AUTOSCALING_REGIONMAP_GOV) $(HA_REGIONMAP_GOV) $(EGW_REGIONMAP_GOV)
templates: merge_region_maps $(UTM_VERSION_DIR) $(TEMPLATES) $(CONVERSION_TEMPLATES) $(EGW_VERSION_DIR) $(EGW_TEMPLATES)

# Always rebuild region maps
ifeq ($(DEVEL),1)
# Only for development: using the newest amis
# We don't use capture groups in the regex, so the sort (for 'newest') is using the
# entire name string like axg9400_verdi-asg-9.375-20160216.2_64_ebs_byol
# Using verdi branch (axg*_verdi) for HA
$(HA_REGIONMAP): $(dir $(HA_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
            --key BYOL --regex '^axg\d+_verdi-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(ADD_TYPES_TO_MAP) $(HA_TYPES_ARGS) --in $@ --out $@

# Using aws branch (asg*_aws) for Autoscaling
$(AUTOSCALING_REGIONMAP): $(dir $(AUTOSCALING_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
	    --key BYOL --regex '^axg\d+_aws-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(ADD_TYPES_TO_MAP) $(AUTOSCALING_TYPES_ARGS) --in $@ --out $@

# Build EGW templates using aws branch
$(EGW_REGIONMAP): $(dir $(EGW_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
	   --key EGW --regex '^egw-\d+\.\d+\.\d+-\d+' > '$@'
	@$(ADD_TYPES_TO_MAP) $(EGW_TYPES_ARGS) --in $@ --out $@

# same for GovCloud ..
# Using verdi branch (axg*_verdi) for HA
$(HA_REGIONMAP_GOV): $(dir $(HA_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' --gov \
            --key BYOL --regex '^axg\d+_verdi-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(ADD_TYPES_TO_MAP) $(HA_TYPES_ARGS) --in $@ --out $@

# Using aws branch (asg*_aws) for Autoscaling
$(AUTOSCALING_REGIONMAP_GOV): $(dir $(AUTOSCALING_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' --gov \
	    --key BYOL --regex '^axg\d+_aws-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'
	@$(ADD_TYPES_TO_MAP) $(AUTOSCALING_TYPES_ARGS) --in $@ --out $@

# Build EGW templates using aws branch
$(EGW_REGIONMAP_GOV): $(dir $(EGW_REGIONMAP))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' --gov \
	   --key EGW --regex '^egw-\d+\.\d+\.\d+-\d+' > '$@'
	@$(ADD_TYPES_TO_MAP) $(EGW_TYPES_ARGS) --in $@ --out $@
else
$(HA_REGIONMAP): tmp
	@echo Building HA RegionMap
	@$(CREATE_REGIONMAP) $(HA_ARGS) --out $@
	@$(ADD_TYPES_TO_MAP) $(HA_TYPES_ARGS) --in $@ --out $@

$(AUTOSCALING_REGIONMAP): tmp
	@echo Building Autoscaling RegionMap
	@$(CREATE_REGIONMAP) $(AUTOSCALING_ARGS) --out $@
	@$(ADD_TYPES_TO_MAP) $(AUTOSCALING_TYPES_ARGS) --in $@ --out $@

$(EGW_REGIONMAP): tmp
	@echo Building EGW RegionMap
	@$(CREATE_REGIONMAP) $(EGW_ARGS) --out $@
	@$(ADD_TYPES_TO_MAP) $(EGW_TYPES_ARGS) --in $@ --out $@

# same for GovCloud ..
$(HA_REGIONMAP_GOV): tmp
	@echo Building HA RegionMap for GovCloud
	@$(CREATE_REGIONMAP) $(HA_ARGS) --gov --out $@
	@$(ADD_TYPES_TO_MAP) $(HA_TYPES_ARGS) --in $@ --out $@

$(AUTOSCALING_REGIONMAP_GOV): tmp
	@echo Building Autoscaling RegionMap for GovCloud
	@$(CREATE_REGIONMAP) $(AUTOSCALING_ARGS) --gov --out $@
	@$(ADD_TYPES_TO_MAP) $(AUTOSCALING_TYPES_ARGS) --in $@ --out $@

$(EGW_REGIONMAP_GOV): tmp
	@echo Building EGW RegionMap for GovCloud
	@$(CREATE_REGIONMAP) $(EGW_ARGS) --gov --out $@
	@$(ADD_TYPES_TO_MAP) $(EGW_TYPES_ARGS) --in $@ --out $@
endif

merge_region_maps:
	jq -s add $(HA_REGIONMAP) $(HA_REGIONMAP_GOV) > $(HA_REGIONMAP_COMBINED) 2>/dev/null; true
	jq -s add $(AUTOSCALING_REGIONMAP) $(AUTOSCALING_REGIONMAP_GOV) > $(AUTOSCALING_REGIONMAP_COMBINED) 2>/dev/null; true
	jq -s add $(EGW_REGIONMAP) $(EGW_REGIONMAP_GOV) > $(EGW_REGIONMAP_COMBINED) 2>/dev/null; true

# Overwrite autoscaling target to use autoscaling region map
templates/autoscaling_waf.template: src/autoscaling_waf.json merge_region_maps
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP_COMBINED) --out $@

templates/%.template: src/%.json merge_region_maps
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP_COMBINED) --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/conversion/$(UTM_VERSION)/autoscaling.template: src/conversion/autoscaling.json merge_region_maps
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP_COMBINED) --out $@

templates/conversion/$(UTM_VERSION)/%.template: src/conversion/%.json merge_region_maps
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP_COMBINED) --out $@

# Create EGW templates from src directory.
templates/egw/$(EGW_VERSION)/%.template: src/egw/%.json merge_region_maps
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(EGW_REGIONMAP_COMBINED) --out $@

$(UTM_VERSION_DIR) $(EGW_VERSION_DIR):
	@echo Creating $@ directory
	@mkdir -p $@
	@echo Linking $(dir $@)current to $(shell basename $@)
	-@ln -sf $(shell basename $@) $(dir $@)current

#tmp dir is not in git and empty. Must be created if it does not exist yet
tmp:
	@mkdir $@

clean:
	rm -rf templates/conversion templates/egw templates/*.template tmp/*.json

.PHONY: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(EGW_REGIONMAP) \
	$(AUTOSCALING_REGIONMAP_GOV) $(HA_REGIONMAP_GOV) $(EGW_REGIONMAP_GOV) \
	$(UTM_VERSION_DIR) clean
