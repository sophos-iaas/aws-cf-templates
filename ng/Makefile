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
TMP := tmp              # tmp dir for region maps, aws ami dump, other intermediate files
TEMPLATES := templates  # template output folder
UTM_VERSION_DIR = $(TEMPLATES)/conversion/$(UTM_VERSION)
EGW_VERSION_DIR = $(TEMPLATES)/egw/$(EGW_VERSION)

# Template paths
STANDALONE_TEMPLATE := $(TEMPLATES)/standalone.template
HA_TEMPLATE := $(TEMPLATES)/ha_cold_standby.template $(TEMPLATES)/ha_warm_standby.template
HA_CONVERSION_TEMPLATE := $(UTM_VERSION_DIR)/ha_cold_standby.template $(UTM_VERSION_DIR)/ha_warm_standby.template
AUTOSCALING_TEMPLATE := $(TEMPLATES)/autoscaling.template
AUTOSCALING_CONVERSION_TEMPLATE := $(UTM_VERSION_DIR)/autoscaling.template
EGW_TEMPLATE := $(EGW_VERSION_DIR)/egw.template

# Several lists of intermediate folders/files per region
ALL_REGIONS := $(shell ./aws_regions.sh)
ALL_REGION_DIRS := $(addprefix $(TMP)/,$(ALL_REGIONS))
ALL_HA_BYOL := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/ha_byol.ami)
ALL_HA_MP := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/ha_mp.ami)
ALL_AS_BYOL := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/as_byol.ami)
ALL_AS_MP := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/as_mp.ami)
ALL_EGW := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/egw.ami)
ALL_ARN := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/arn)
ALL_DEFAULT_ITYPE := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/default_instance_type)  # default instance type for EGW, UTM
ALL_LARGE_ITYPE := $(foreach region,$(ALL_REGIONS),$(TMP)/$(region)/larger_instance_type)     # larger instance type for Queen

# Misc
Q=
ECHO=$(Q)echo
BUILD_JSON=./json_builder.sh
MERGE_JSON=jq -s 'reduce .[] as $$hash ({}; . * $$hash)'
ADD_REGION_MAP := jq -s '.[0].Mappings.RegionMap=.[1] | .[0]'
ifeq ($(PUBLIC),1)
	PUBLIC="--public"
else
	PUBLIC=
endif

# Function to filter the region name from a folder name
define get_region
$(lastword $(subst /, ,$(dir $(1))))
endef

## Targets
# always clean before building new templates!
enforce_clean:
	rm -rf $(TMP) $(TEMPLATES)
	$(Q)mkdir -p $(ALL_REGION_DIRS) $(TEMPLATES)

-include enforce_clean


all: $(STANDALONE_TEMPLATE) $(HA_TEMPLATE) $(HA_CONVERSION_TEMPLATE) $(AUTOSCALING_TEMPLATE) $(AUTOSCALING_CONVERSION_TEMPLATE) $(EGW_TEMPLATE)

## Region Maps
$(TMP)/standalone.map: $(ALL_HA_BYOL) $(ALL_HA_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	(\
		$(BUILD_JSON) Hourly ha_mp.ami ;\
		$(BUILD_JSON) BYOL ha_byol.ami ;\
		$(BUILD_JSON) ARN arn ;\
		$(BUILD_JSON) HAInstanceType default_instance_type \
	) | $(MERGE_JSON) > $@

$(TMP)/autoscaling.map: $(ALL_AS_BYOL) $(ALL_AS_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE) $(ALL_LARGE_ITYPE)
	(\
		$(BUILD_JSON) Hourly as_mp.ami ;\
		$(BUILD_JSON) BYOL as_byol.ami ;\
		$(BUILD_JSON) ARN arn ;\
		$(BUILD_JSON) QueenInstanceType larger_instance_type ;\
		$(BUILD_JSON) WorkerInstanceType default_instance_type \
	) | $(MERGE_JSON) > $@

$(TMP)/egw.map: $(ALL_EGW) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	(\
		$(BUILD_JSON) EGW egw.ami ;\
		$(BUILD_JSON) ARN arn ;\
		$(BUILD_JSON) EGWInstanceType default_instance_type \
	) | $(MERGE_JSON) > $@

# Region map enrichment
$(TMP)/%/arn: static/%/arn
	cp $^ $@

$(TMP)/%/arn: static/default/arn
	cp $^ $@

$(TMP)/%/default_instance_type: static/%/default_instance_type
	cp $^ $@

$(TMP)/%/default_instance_type: static/default/default_instance_type
	cp $^ $@

$(TMP)/%/larger_instance_type: static/%/larger_instance_type
	cp $^ $@

$(TMP)/%/larger_instance_type: static/default/larger_instance_type
	cp $^ $@

## Specific AMIs
%/egw.ami: %/aws.dump
	jq -r '[.Images[] | select(.Name | startswith("egw-"))][-1].ImageId' $^ > $@

%/ha_byol.ami: %/aws.dump
	jq -r '[.Images[] | select(.Name | match("^sophos_utm_standalone_.*byol$$"))][-1].ImageId' $^ > $@

%/ha_mp.ami: %/aws.dump
	jq -r '[.Images[] | select(.Name | match("^sophos_utm_standalone_.*mp$$"))][-1].ImageId' $^ > $@

%/as_byol.ami: %/aws.dump
	jq -r '[.Images[] | select(.Name | match("^sophos_utm_autoscaling_.*byol$$"))][-1].ImageId' $^ > $@

%/as_mp.ami: %/aws.dump
	jq -r '[.Images[] | select(.Name | match("^sophos_utm_autoscaling_.*mp$$"))][-1].ImageId' $^ > $@

## AWS AMI dump
%/aws.dump:
	./ami_dumper.sh --region $(call get_region,$@) $(PUBLIC) --out $@

## Build actual templates by merging region map and template source
$(UTM_VERSION_DIR) $(EGW_VERSION_DIR):
	@echo Creating $@ directory
	@mkdir -p $@
	@echo Linking $(dir $@)current to $(shell basename $@)
	-@ln -sf $(shell basename $@) $(dir $@)current

# HA (warm, cold), Standalone
$(TEMPLATES)/%.template: src/%.json $(TMP)/standalone.map
	$(ADD_REGION_MAP) $^ > $@

# Conversion HA (warm, cold)
$(UTM_VERSION_DIR)/%.template: $(UTM_VERSION_DIR) src/conversion/%.json $(TMP)/standalone.map
	$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Autoscaling
$(TEMPLATES)/autoscaling.template: src/autoscaling.json $(TMP)/autoscaling.map
	$(ADD_REGION_MAP) $^ > $@

# Conversion Autoscaling
$(UTM_VERSION_DIR)/autoscaling.template: $(UTM_VERSION_DIR) src/conversion/autoscaling.json $(TMP)/autoscaling.map
	$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# EGW
$(EGW_VERSION_DIR)/%.template: $(EGW_VERSION_DIR) src/egw.json $(TMP)/egw.map
	$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Don't remove intermediate files
.PRECIOUS: %/aws.dump

.PHONY: enforce_clean %/aws.dump
