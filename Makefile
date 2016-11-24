## Configuration
# UTM_VERSION = *_verdi branch version that has been deployed to aws
# The default here is only for convenience, and usually is passed with the
# jenkins build job or during execution
UTM_VERSION ?= 9.408
# EGW_VERSION = version of interface paramters (if they change in an
# incompatible way, the version updates also)
EGW_VERSION ?= 1.0
# Build templates using public AMIs (default: no)
PUBLIC ?= 0
# Execute make in parallel and disable internal rules
MAKEFLAGS += --jobs=100 -r

## Variables
SHELL := /bin/bash
# tmp dir for region maps, aws ami dump, other intermediate files
TMP_OUT := tmp
# template output folder
TEMPLATES := templates
UTM_PATH = $(TEMPLATES)/utm
CONVERSION_PATH = $(TEMPLATES)/utm/conversion/$(UTM_VERSION)
EGW_VERSION_DIR = $(TEMPLATES)/egw/$(EGW_VERSION)

# Template paths
STANDALONE_TEMPLATE := $(UTM_PATH)/standalone.template
HA_TEMPLATE := $(UTM_PATH)/ha_standalone.template $(UTM_PATH)/ha_warm_standby.template
HA_CONVERSION_TEMPLATE := $(CONVERSION_PATH)/ha_standalone.template $(CONVERSION_PATH)/ha_warm_standby.template
AUTOSCALING_TEMPLATE := $(UTM_PATH)/autoscaling.template
AUTOSCALING_CONVERSION_TEMPLATE := $(CONVERSION_PATH)/autoscaling.template
EGW_TEMPLATE := $(EGW_VERSION_DIR)/egw.template

# Several lists of intermediate folders/files per region
ALL_REGIONS := $(shell ./bin/aws_regions.sh)
ALL_REGION_DIRS := $(addprefix $(TMP_OUT)/,$(ALL_REGIONS))

ALL_HA_BYOL := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/ha_byol.ami)
ALL_HA_MP := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/ha_mp.ami)
ALL_AS_BYOL := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/as_byol.ami)
ALL_AS_MP := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/as_mp.ami)
ALL_EGW := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/egw.ami)

ALL_ARN := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/arn.static)
# default instance type for EGW, UTM
ALL_DEFAULT_ITYPE := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/default_instance_type.static)
# larger instance type for Queen
ALL_LARGE_ITYPE := $(foreach region,$(ALL_REGIONS),$(TMP_OUT)/$(region)/larger_instance_type.static)

# Misc
Q=@
ECHO=$(Q)echo -e
BUILD_JSON=./bin/json_builder.sh
MERGE_JSON=jq -s 'reduce .[] as $$hash ({}; . * $$hash)'
ADD_REGION_MAP=jq -s '.[0].Mappings.RegionMap=.[1] | .[0]'
AMI_NAME=$(ECHO) "[AMI] $(call get_region,$@) \t$(call get_product,$@)\t$$(cat $@)"

ifeq ($(PUBLIC),1)
PUBLIC_AMIS=--public
STANDALONE_REGEX=asg
AUTOSCALING_REGEX=axg9400_aws-asg
STANDALONE_BYOL_REGEX=^asg-.*byol.*$$
STANDALONE_MP_REGEX=^asg-.*mp.*$$
AUTOSCALING_BYOL_REGEX=^axg9400_aws-asg-.*byol.*$$
AUTOSCALING_MP_REGEX=^axg9400_aws-asg-.*mp.*$$
else
PUBLIC_AMIS=
STANDALONE_BYOL_REGEX=^sophos_utm_standalone_.*byol$$
STANDALONE_MP_REGEX=^sophos_utm_standalone_.*mp$$
AUTOSCALING_BYOL_REGEX=^sophos_utm_autoscaling_.*byol$$
AUTOSCALING_MP_REGEX=^sophos_utm_autoscaling_.*mp$$
endif

# get_region returns region name from a file path (e.g. tmp/us-east-1/foo.bar -> us-east-1)
define get_region
$(lastword $(subst /, ,$(dir $(1))))
endef
# get_product returns product name from a ami file path (e.g. tmp/us-east-1/as_mp.ami -> as_mp)
define get_product
$(word 1 ,$(subst ., ,$(notdir $(1))))
endef

## Targets
# build all templates
all: $(STANDALONE_TEMPLATE) $(HA_TEMPLATE) $(HA_CONVERSION_TEMPLATE) $(AUTOSCALING_TEMPLATE) $(AUTOSCALING_CONVERSION_TEMPLATE) $(EGW_TEMPLATE)

# always clean before building new templates!
clean:
	rm -rf $(TMP_OUT) $(TEMPLATES)
	$(Q)mkdir -p $(ALL_REGION_DIRS) $(TEMPLATES)

-include clean


## Region Maps
$(TMP_OUT)/standalone.map: $(ALL_HA_BYOL) $(ALL_HA_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	$(ECHO) "[REGIONMAP] standalone"
	$(Q)(\
		$(BUILD_JSON) Hourly ha_mp.ami ;\
		$(BUILD_JSON) BYOL ha_byol.ami ;\
		$(BUILD_JSON) ARN arn.static ;\
		$(BUILD_JSON) HAInstanceType default_instance_type.static \
	) | $(MERGE_JSON) > $@

$(TMP_OUT)/autoscaling.map: $(ALL_AS_BYOL) $(ALL_AS_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE) $(ALL_LARGE_ITYPE)
	$(ECHO) "[REGIONMAP] autoscaling"
	$(Q)(\
		$(BUILD_JSON) Hourly as_mp.ami ;\
		$(BUILD_JSON) BYOL as_byol.ami ;\
		$(BUILD_JSON) ARN arn.static ;\
		$(BUILD_JSON) QueenInstanceType larger_instance_type.static ;\
		$(BUILD_JSON) SwarmInstanceType default_instance_type.static \
	) | $(MERGE_JSON) > $@

$(TMP_OUT)/egw.map: $(ALL_EGW) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	$(ECHO) "[REGIONMAP] egw"
	$(Q)(\
		$(BUILD_JSON) EGW egw.ami ;\
		$(BUILD_JSON) ARN arn.static ;\
		$(BUILD_JSON) EGWInstanceType default_instance_type.static \
	) | $(MERGE_JSON) > $@

## Region Map enrichment
# Copy from region specific file, if existing, otherwise use default
# static/us-east-1/arn.static out/us-east-1/arn.static
$(ALL_ARN) $(ALL_DEFAULT_ITYPE) $(ALL_LARGE_ITYPE):
	$(Q)cp static/$(call get_region,$@)/$(notdir $@) $@ 2> /dev/null || cp static/default/$(notdir $@) $@

## Specific AMIs
%/egw.ami: %/aws.dump
	$(Q)jq -r '[.Images[] | select(.Name | startswith("sophos_egw_"))][-1] | [.ImageId, .Name] | @tsv' $^ > $@
	$(AMI_NAME)

%/ha_byol.ami: %/aws.dump
	$(Q)jq -r '[.Images[] | select(.Name | match("$(STANDALONE_BYOL_REGEX)"))][-1] | [.ImageId, .Name] | @tsv' $^ > $@
	$(AMI_NAME)

%/ha_mp.ami: %/aws.dump
	$(Q)jq -r '[.Images[] | select(.Name | match("$(STANDALONE_MP_REGEX)"))][-1] | [.ImageId, .Name] | @tsv' $^ > $@
	$(AMI_NAME)

%/as_byol.ami: %/aws.dump
	$(Q)jq -r '[.Images[] | select(.Name | match("$(AUTOSCALING_BYOL_REGEX)"))][-1] | [.ImageId, .Name] | @tsv' $^ > $@
	$(AMI_NAME)

%/as_mp.ami: %/aws.dump
	$(Q)jq -r '[.Images[] | select(.Name | match("$(AUTOSCALING_MP_REGEX)"))][-1] | [.ImageId, .Name] | @tsv' $^ > $@
	$(AMI_NAME)

## In GovCloud we put byol AMI to mp, because there is no marketplace
$(TMP_OUT)/us-gov-west-1/as_mp.ami: $(TMP_OUT)/us-gov-west-1/as_byol.ami
	$(Q)cp $^ $@

$(TMP_OUT)/us-gov-west-1/ha_mp.ami: $(TMP_OUT)/us-gov-west-1/ha_byol.ami
	$(Q)cp $^ $@

## AWS AMI dump
%/aws.dump:
	$(ECHO) "[AMI_DUMP] $(call get_region,$@)"
	$(Q)./bin/ami_dumper.sh --region $(call get_region,$@) $(PUBLIC_AMIS) --out $@

## Build actual templates by merging region map and template source
# convert yaml sources to json
src/%.json: src/%.yaml
	$(ECHO) "[YAML2JSON] $< -> $@"
	$(Q)./bin/yaml2json $< > $@

$(UTM_PATH):
	$(Q)mkdir -p $@

$(CONVERSION_PATH) $(EGW_VERSION_DIR):
	$(Q)mkdir -p $@
	-$(Q)ln -sf $(shell basename $@) $(dir $@)current

# HA (warm, cold), Standalone
$(UTM_PATH)/%.template: $(UTM_PATH) src/%.json $(TMP_OUT)/standalone.map
	$(ECHO) "[TEMPLATE] $@"
	$(Q)$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Conversion HA (warm, cold)
$(CONVERSION_PATH)/%.template: $(CONVERSION_PATH) src/conversion/%.json $(TMP_OUT)/standalone.map
	$(ECHO) "[TEMPLATE] $@"
	$(Q)$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Autoscaling
$(AUTOSCALING_TEMPLATE): $(UTM_PATH) src/autoscaling.json $(TMP_OUT)/autoscaling.map
	$(ECHO) "[TEMPLATE] $@"
	$(Q)$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Conversion Autoscaling
$(AUTOSCALING_CONVERSION_TEMPLATE): $(CONVERSION_PATH) src/conversion/autoscaling.json $(TMP_OUT)/autoscaling.map
	$(ECHO) "[TEMPLATE] $@"
	$(Q)$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# EGW
$(EGW_VERSION_DIR)/%.template: $(EGW_VERSION_DIR) src/egw/egw.json $(TMP_OUT)/egw.map
	$(ECHO) "[TEMPLATE] $@"
	$(Q)$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Don't remove intermediate aws dump files
.PRECIOUS: %/aws.dump

# Somehow these two intermediate files need to be mentioned explicitly to get deleted
.INTERMEDIATE: src/autoscaling.json src/conversion/autoscaling.json

.PHONY: clean %/aws.dump
