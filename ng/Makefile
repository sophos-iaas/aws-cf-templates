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

ALL_ARN := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/arn)
ALL_DEFAULT_ITYPE := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/default_instance_type)
ALL_LARGE_ITYPE := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/larger_instance_type)

Q=
ECHO=$(Q)echo

.PHONY: enforce_clean
enforce_clean:
	rm -rf $(OUT)
	$(Q)mkdir -p $(ALL_REGION_DIRS)

-include enforce_clean

MAKEFLAGS += --jobs=100 -r

all: $(OUT)/standalone.map $(OUT)/autoscaling.map $(OUT)/egw.map

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


# Don't remove intermediate files
.PRECIOUS: %/aws.dump

.PHONY: %/aws.dump
