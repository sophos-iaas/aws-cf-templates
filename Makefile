## Configuration
# UTM_VERSION = *_verdi branch version that has been deployed to aws
# The default here is only for convenience, and usually is passed with the
# jenkins build job or during execution
UTM_VERSION ?= 9.406
# EGW_VERSION = version of interface paramters (if they change in an
# incompatible way, the version updates also)
EGW_VERSION ?= 1.0

# devel AMI owner ID
AMI_OWNER := 159737981378
export AMI_OWNER
# GovCloud AMI owner ID
GOV_OWNER := 219379113529

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

## region names
REGULAR_REGION = tmp/us-east-1
GOV_REGION = tmp/us-gov-west-1
COMBINED_REGION = tmp/combined
export AWS_DEFAULT_REGION

## file sets
HA_REGIONMAP                   = $(REGULAR_REGION)/HA_REGIONMAP.json
AUTOSCALING_REGIONMAP          = $(REGULAR_REGION)/AUTOSCALING_REGIONMAP.json
EGW_REGIONMAP                  = $(REGULAR_REGION)/EGW_REGIONMAP.json
HA_REGIONMAP_GOV               = $(GOV_REGION)/HA_REGIONMAP.json
AUTOSCALING_REGIONMAP_GOV      = $(GOV_REGION)/AUTOSCALING_REGIONMAP.json
EGW_REGIONMAP_GOV              = $(GOV_REGION)/EGW_REGIONMAP.json
HA_REGIONMAP_COMBINED          = $(COMBINED_REGION)/HA_REGIONMAP.json
AUTOSCALING_REGIONMAP_COMBINED = $(COMBINED_REGION)/AUTOSCALING_REGIONMAP.json
EGW_REGIONMAP_COMBINED         = $(COMBINED_REGION)/EGW_REGIONMAP.json
UTM_VERSION_DIR                = templates/conversion/$(UTM_VERSION)
EGW_VERSION_DIR                = templates/egw/$(EGW_VERSION)

TEMPLATES := $(addprefix templates/, $(patsubst %.json,%.template,$(notdir $(wildcard src/*.json))))
CONVERSION_TEMPLATES := $(addprefix templates/conversion/$(UTM_VERSION)/, $(patsubst %.json,%.template,$(notdir $(wildcard src/conversion/*.json))))
EGW_TEMPLATES := templates/egw/$(EGW_VERSION)/egw.template

## bins
BUNDLE_EXEC = bundle exec
CREATE_REGIONMAP = $(BUNDLE_EXEC) ./bin/create_regionmap
CREATE_REGIONMAP_DEV = $(BUNDLE_EXEC) ./bin/create_regionmap_dev
BUILD_TEMPLATE = $(BUNDLE_EXEC) ./bin/build_template
ADD_TYPES_TO_MAP = $(BUNDLE_EXEC) ./bin/add_types_to_map

AWS_PROFILE ?= default
export AWS_PROFILE

# templates for regular cloud
regular: clean region_map_regular_cloud templates

# only egw templates
egw_publish: clean $(EGW_REGIONMAP) $(EGW_VERSION_DIR) $(EGW_TEMPLATES)

# templates for regular and gov cloud
all: export BOTH_CLOUDS = true
all: region_map_regular_cloud region_map_gov_cloud templates

region_map_regular_cloud: AWS_DEFAULT_REGION = $(shell basename $(REGULAR_REGION))
region_map_regular_cloud: $(HA_REGIONMAP) $(AUTOSCALING_REGIONMAP) $(EGW_REGIONMAP)
# DEVEL_OWNER is changed to GovCloud owner ID
region_map_gov_cloud: AMI_OWNER = $(GOV_OWNER)
region_map_gov_cloud: AWS_DEFAULT_REGION = $(shell basename $(GOV_REGION))
region_map_gov_cloud: export AWS_PROFILE = govcloud_build
region_map_gov_cloud: export BOTH_CLOUDS = true
region_map_gov_cloud: $(HA_REGIONMAP_COMBINED) $(AUTOSCALING_REGIONMAP_COMBINED) $(EGW_REGIONMAP_COMBINED)
templates: $(UTM_VERSION_DIR) $(TEMPLATES) $(CONVERSION_TEMPLATES) $(EGW_VERSION_DIR) $(EGW_TEMPLATES)

# Always rebuild region maps
ifeq ($(DEVEL),1)
# Only for development: using the newest amis
# We don't use capture groups in the regex, so the sort (for 'newest') is using the
# entire name string like axg9400_verdi-asg-9.375-20160216.2_64_ebs_byol
# Using verdi branch (axg*_verdi) for HA
$(HA_REGIONMAP): $(filter-out $(wildcard $(REGULAR_REGION)), $(REGULAR_REGION))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
            --key BYOL --regex '^axg\d+_verdi-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'

# Using aws branch (asg*_aws) for Autoscaling
$(AUTOSCALING_REGIONMAP): $(filter-out $(wildcard $(REGULAR_REGION)), $(REGULAR_REGION))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
	    --key BYOL --regex '^axg\d+_aws-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@'

# Build EGW templates using aws branch
$(EGW_REGIONMAP): $(filter-out $(wildcard $(REGULAR_REGION)), $(REGULAR_REGION))
	@$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
	   --key EGW --regex '^egw-\d+\.\d+\.\d+-\d+' > '$@'

# same for GovCloud ..
# Using verdi branch (axg*_verdi) for HA
$(HA_REGIONMAP_GOV): $(filter-out $(wildcard $(GOV_REGION)), $(GOV_REGION))
	$(if $(filter $(BOTH_CLOUDS),true), @$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
            --key BYOL --regex '^axg\d+_verdi-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@', > $@)

# Using aws branch (asg*_aws) for Autoscaling
$(AUTOSCALING_REGIONMAP_GOV): $(filter-out $(wildcard $(GOV_REGION)), $(GOV_REGION))
	$(if $(filter $(BOTH_CLOUDS),true), @$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
	    --key BYOL --regex '^axg\d+_aws-asg-\d+\.\d+-\d+\.\d+_64_ebs_byol$$' > '$@', > $@)

# Build EGW templates using aws branch
$(EGW_REGIONMAP_GOV): $(filter-out $(wildcard $(GOV_REGION)), $(GOV_REGION))
	$(if $(filter $(BOTH_CLOUDS),true), @$(CREATE_REGIONMAP_DEV) --owner '$(AMI_OWNER)' \
	   --key EGW --regex '^egw-\d+\.\d+\.\d+-\d+' > '$@', > $@)
else
$(HA_REGIONMAP): $(filter-out $(wildcard $(REGULAR_REGION)), $(REGULAR_REGION))
	@echo Building HA RegionMap \($(AWS_DEFAULT_REGION)\)
	@$(CREATE_REGIONMAP) $(HA_ARGS) --out $@

$(AUTOSCALING_REGIONMAP): $(filter-out $(wildcard $(REGULAR_REGION)), $(REGULAR_REGION))
	@echo Building Autoscaling RegionMap \($(AWS_DEFAULT_REGION)\)
	@$(CREATE_REGIONMAP) $(AUTOSCALING_ARGS) --out $@

$(EGW_REGIONMAP): $(filter-out $(wildcard $(REGULAR_REGION)), $(REGULAR_REGION))
	@echo Building EGW RegionMap \($(AWS_DEFAULT_REGION)\)
	@$(CREATE_REGIONMAP) $(EGW_ARGS) --out $@

# same for GovCloud ..
$(HA_REGIONMAP_GOV): $(filter-out $(wildcard $(GOV_REGION)), $(GOV_REGION))
	@echo Building HA RegionMap for GovCloud \($(AWS_DEFAULT_REGION)\)
	$(if $(filter $(BOTH_CLOUDS),true), @$(CREATE_REGIONMAP) $(HA_ARGS) --out $@, > $@)

$(AUTOSCALING_REGIONMAP_GOV): $(filter-out $(wildcard $(GOV_REGION)), $(GOV_REGION))
	@echo Building Autoscaling RegionMap for GovCloud \($(AWS_DEFAULT_REGION)\) when required
	$(if $(filter $(BOTH_CLOUDS),true), @$(CREATE_REGIONMAP) $(AUTOSCALING_ARGS) --out $@ , > $@ )

$(EGW_REGIONMAP_GOV): $(filter-out $(wildcard $(GOV_REGION)), $(GOV_REGION))
	@echo Building EGW RegionMap for GovCloud \($(AWS_DEFAULT_REGION)\) when required
	$(if $(filter $(BOTH_CLOUDS),true), @$(CREATE_REGIONMAP) $(EGW_ARGS) --out $@, > $@)
endif

## combine region maps
$(HA_REGIONMAP_COMBINED): $(HA_REGIONMAP) $(HA_REGIONMAP_GOV) $(COMBINED_REGION)
	jq -s add $(HA_REGIONMAP) $(HA_REGIONMAP_GOV) > $@
	@$(ADD_TYPES_TO_MAP) $(HA_TYPES_ARGS) --in $@ --out $@

$(AUTOSCALING_REGIONMAP_COMBINED): $(AUTOSCALING_REGIONMAP) $(AUTOSCALING_REGIONMAP_GOV) $(COMBINED_REGION)
	jq -s add $(AUTOSCALING_REGIONMAP) $(AUTOSCALING_REGIONMAP_GOV) > $@
	@$(ADD_TYPES_TO_MAP) $(AUTOSCALING_TYPES_ARGS) --in $@ --out $@

$(EGW_REGIONMAP_COMBINED): $(EGW_REGIONMAP) $(EGW_REGIONMAP_GOV) $(COMBINED_REGION)
	jq -s add $(EGW_REGIONMAP) $(EGW_REGIONMAP_GOV) > $@
	@$(ADD_TYPES_TO_MAP) $(EGW_TYPES_ARGS) --in $@ --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/autoscaling_waf.template: src/autoscaling_waf.json $(AUTOSCALING_REGIONMAP_COMBINED)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP_COMBINED) --out $@

templates/%.template: src/%.json $(HA_REGIONMAP_COMBINED)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP_COMBINED) --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/conversion/$(UTM_VERSION)/autoscaling.template: src/conversion/autoscaling.json $(AUTOSCALING_REGIONMAP_COMBINED)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP_COMBINED) --out $@

templates/conversion/$(UTM_VERSION)/%.template: src/conversion/%.json $(HA_REGIONMAP_COMBINED)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP_COMBINED) --out $@

# Create EGW templates from src directory.
templates/egw/$(EGW_VERSION)/%.template: src/egw/%.json $(EGW_REGIONMAP_COMBINED)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(EGW_REGIONMAP_COMBINED) --out $@

$(UTM_VERSION_DIR) $(EGW_VERSION_DIR):
	@echo Creating $@ directory
	@mkdir -p $@
	@echo Linking $(dir $@)current to $(shell basename $@)
	-@ln -sf $(shell basename $@) $(dir $@)current

#tmp dir is not in git and empty. Must be created if it does not exist yet
tmp/%:
	@mkdir -p $@

clean:
	rm -rf templates/conversion templates/egw templates/*.template tmp

.PHONY: $(UTM_VERSION_DIR) clean
