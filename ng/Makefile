## Configuration
# UTM_VERSION = *_verdi branch version that has been deployed to aws
# The default here is only for convenience, and usually is passed with the
# jenkins build job or during execution
UTM_VERSION ?= 9.408
# EGW_VERSION = version of interface paramters (if they change in an
# incompatible way, the version updates also)
EGW_VERSION ?= 1.0


define get_region
$(lastword $(subst /, ,$(dir $(1))))
endef

PUBLIC?=0
ifeq ($(PUBLIC),1)
	PUBLIC="--public"
else
	PUBLIC=
endif

OUT := out
TEMPLATES := templates
UTM_VERSION_DIR = $(TEMPLATES)/conversion/$(UTM_VERSION)
EGW_VERSION_DIR = $(TEMPLATES)/egw/$(EGW_VERSION)
STATIC := $(abspath static)
ALL_REGIONS := $(shell ./aws_regions.sh)
ALL_REGION_DIRS := $(addprefix $(OUT)/,$(ALL_REGIONS))

ALL_HA_BYOL := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/ha_byol.ami)
ALL_HA_MP := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/ha_mp.ami)
ALL_AS_BYOL := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/as_byol.ami)
ALL_AS_MP := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/as_mp.ami)
ALL_EGW := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/egw.ami)

ALL_ARN := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/arn)
ALL_DEFAULT_ITYPE := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/default_instance_type)
ALL_LARGE_ITYPE := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/larger_instance_type)

Q=
ECHO=$(Q)echo

.PHONY: enforce_clean
enforce_clean:
	rm -rf $(OUT) $(TEMPLATES)
	$(Q)mkdir -p $(ALL_REGION_DIRS) $(TEMPLATES)

-include enforce_clean

MAKEFLAGS += --jobs=100 -r

STANDALONE_TEMPLATE := $(TEMPLATES)/standalone.template
HA_TEMPLATE := $(TEMPLATES)/ha_cold_standby.template $(TEMPLATES)/ha_warm_standby.template
HA_CONVERSION_TEMPLATE := $(UTM_VERSION_DIR)/ha_cold_standby.template $(UTM_VERSION_DIR)/ha_warm_standby.template
AUTOSCALING_TEMPLATE := $(TEMPLATES)/autoscaling.template
AUTOSCALING_CONVERSION_TEMPLATE := $(UTM_VERSION_DIR)/autoscaling.template
EGW_TEMPLATE := $(EGW_VERSION_DIR)/egw.template
ADD_REGION_MAP := jq -s '.[0].Mappings.RegionMap=.[1] | .[0]'

all: $(STANDALONE_TEMPLATE) $(HA_TEMPLATE) $(HA_CONVERSION_TEMPLATE) $(AUTOSCALING_TEMPLATE) $(AUTOSCALING_CONVERSION_TEMPLATE) $(EGW_TEMPLATE)

$(OUT)/standalone.map: $(ALL_HA_BYOL) $(ALL_HA_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	./json_builder.sh Hourly ha_mp.ami | jq -s add > $@.mp
	./json_builder.sh BYOL ha_byol.ami | jq -s add > $@.byol
	./json_builder.sh ARN arn | jq -s add > $@.arn
	./json_builder.sh HAInstanceType default_instance_type | jq -s add > $@.itype
	jq -s ".[0] * .[1] * .[2] * .[3]" $@.mp $@.byol $@.arn $@.itype > $@

$(OUT)/autoscaling.map: $(ALL_AS_BYOL) $(ALL_AS_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE) $(ALL_LARGE_ITYPE)
	./json_builder.sh Hourly as_mp.ami | jq -s add > $@.mp
	./json_builder.sh BYOL as_byol.ami | jq -s add > $@.byol
	./json_builder.sh ARN arn | jq -s add > $@.arn
	./json_builder.sh QueenInstanceType larger_instance_type | jq -s add > $@.qitype
	./json_builder.sh WorkerInstanceType default_instance_type | jq -s add > $@.witype
	jq -s ".[0] * .[1] * .[2] * .[3] * .[4]" $@.mp $@.byol $@.arn $@.qitype $@.witype > $@

$(OUT)/egw.map: $(ALL_EGW) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	./json_builder.sh EGW egw.ami | jq -s add > $@.ami
	./json_builder.sh ARN arn | jq -s add > $@.arn
	./json_builder.sh EGWInstanceType default_instance_type | jq -s add > $@.itype
	jq -s ".[0] * .[1] * .[2]" $@.ami $@.arn $@.itype > $@

$(OUT)/%/arn: static/%/arn
	echo $(STATIC)
	cp $^ $@

$(OUT)/%/arn: static/default/arn
	cp $^ $@

$(OUT)/%/default_instance_type: static/%/default_instance_type
	cp $^ $@

$(OUT)/%/default_instance_type: static/default/default_instance_type
	cp $^ $@

$(OUT)/%/larger_instance_type: static/%/larger_instance_type
	cp $^ $@

$(OUT)/%/larger_instance_type: static/default/larger_instance_type
	cp $^ $@

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

%/aws.dump:
	./ami_dumper.sh --region $(call get_region,$@) $(PUBLIC) --out $@

$(UTM_VERSION_DIR) $(EGW_VERSION_DIR):
	@echo Creating $@ directory
	@mkdir -p $@
	@echo Linking $(dir $@)current to $(shell basename $@)
	-@ln -sf $(shell basename $@) $(dir $@)current

# HA (warm, cold), Standalone
$(TEMPLATES)/%.template: src/%.json $(OUT)/standalone.map
	$(ADD_REGION_MAP) $^ > $@

# Conversion HA (warm, cold)
$(UTM_VERSION_DIR)/%.template: $(UTM_VERSION_DIR) src/conversion/%.json $(OUT)/standalone.map
	$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Autoscaling
$(TEMPLATES)/autoscaling.template: src/autoscaling.json $(OUT)/autoscaling.map
	$(ADD_REGION_MAP) $^ > $@

# Conversion Autoscaling
$(UTM_VERSION_DIR)/autoscaling.template: $(UTM_VERSION_DIR) src/conversion/autoscaling.json $(OUT)/autoscaling.map
	$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# EGW
$(EGW_VERSION_DIR)/%.template: $(EGW_VERSION_DIR) src/egw.json $(OUT)/egw.map
	$(ADD_REGION_MAP) $(filter-out $<,$^) > $@

# Don't remove intermediate files
.PRECIOUS: %/aws.dump

.PHONY: %/aws.dump
