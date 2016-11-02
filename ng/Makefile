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
STATIC := $(abspath static)
ALL_REGIONS := $(shell ./aws_regions.sh)
ALL_REGION_DIRS := $(addprefix $(OUT)/,$(ALL_REGIONS))

ALL_HA_BYOL := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/ha_byol.ami)
ALL_HA_MP := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/ha_mp.ami)
ALL_AS_BYOL := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/as_byol.ami)
ALL_AS_MP := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/as_mp.ami)
ALL_EGW := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/egw.ami)

ALL_ARN := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/arn.static)
ALL_DEFAULT_ITYPE := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/default_instance_type.static)
ALL_LARGE_ITYPE := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/larger_instance_type.static)

Q=@
ECHO=$(Q)echo
BUILD_JSON=./json_builder.sh
MERGE_JSON=jq -s 'reduce .[] as $$hash ({}; . * $$hash)'

.PHONY: enforce_clean
enforce_clean:
	rm -rf $(OUT)
	$(Q)mkdir -p $(ALL_REGION_DIRS)

-include enforce_clean

MAKEFLAGS += --jobs=100 -r

all: $(OUT)/standalone.map $(OUT)/autoscaling.map $(OUT)/egw.map

$(OUT)/standalone.map: $(ALL_HA_BYOL) $(ALL_HA_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	$(ECHO) "[REGIONMAP] standalone"
	$(Q)(\
		$(BUILD_JSON) Hourly ha_mp.ami ;\
		$(BUILD_JSON) BYOL ha_byol.ami ;\
		$(BUILD_JSON) ARN arn.static ;\
		$(BUILD_JSON) HAInstanceType default_instance_type.static \
	) | $(MERGE_JSON) > $@

$(OUT)/autoscaling.map: $(ALL_AS_BYOL) $(ALL_AS_MP) $(ALL_ARN) $(ALL_DEFAULT_ITYPE) $(ALL_LARGE_ITYPE)
	$(ECHO) "[REGIONMAP] autoscaling"
	$(Q)(\
		$(BUILD_JSON) Hourly as_mp.ami ;\
		$(BUILD_JSON) BYOL as_byol.ami ;\
		$(BUILD_JSON) ARN arn.static ;\
		$(BUILD_JSON) QueenInstanceType larger_instance_type.static ;\
		$(BUILD_JSON) WorkerInstanceType default_instance_type.static \
	) | $(MERGE_JSON) > $@

$(OUT)/egw.map: $(ALL_EGW) $(ALL_ARN) $(ALL_DEFAULT_ITYPE)
	$(ECHO) "[REGIONMAP] egw"
	$(Q)(\
		$(BUILD_JSON) EGW egw.ami ;\
		$(BUILD_JSON) ARN arn.static ;\
		$(BUILD_JSON) EGWInstanceType default_instance_type.static \
	) | $(MERGE_JSON) > $@

# Copy from region specific file, if existing, otherwise use default
# static/us-east-1/arn.static out/us-east-1/arn.static
$(ALL_ARN) $(ALL_DEFAULT_ITYPE) $(ALL_LARGE_ITYPE):
	$(ECHO) "[STATIC] $@"
	$(Q)cp static/$(call get_region,$@)/$(notdir $@) $@ 2> /dev/null || cp static/default/$(notdir $@) $@

%/egw.ami: %/aws.dump
	$(ECHO) "[AMI] $@"
	$(Q)jq -r '[.Images[] | select(.Name | startswith("egw-"))][-1].ImageId' $^ > $@

%/ha_byol.ami: %/aws.dump
	$(ECHO) "[AMI] $@"
	$(Q)jq -r '[.Images[] | select(.Name | match("^sophos_utm_standalone_.*byol$$"))][-1].ImageId' $^ > $@

%/ha_mp.ami: %/aws.dump
	$(ECHO) "[AMI] $@"
	$(Q)jq -r '[.Images[] | select(.Name | match("^sophos_utm_standalone_.*mp$$"))][-1].ImageId' $^ > $@

%/as_byol.ami: %/aws.dump
	$(ECHO) "[AMI] $@"
	$(Q)jq -r '[.Images[] | select(.Name | match("^sophos_utm_autoscaling_.*byol$$"))][-1].ImageId' $^ > $@

%/as_mp.ami: %/aws.dump
	$(ECHO) "[AMI] $@"
	$(Q)jq -r '[.Images[] | select(.Name | match("^sophos_utm_autoscaling_.*mp$$"))][-1].ImageId' $^ > $@

%/aws.dump:
	$(ECHO) "[AMI_DUMP] $(call get_region,$@)"
	$(Q)./ami_dumper.sh --region $(call get_region,$@) $(PUBLIC) --out $@


# Don't remove intermediate files
.PRECIOUS: %/aws.dump

.PHONY: %/aws.dump
