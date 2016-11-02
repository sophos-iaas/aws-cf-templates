define get_region
$(lastword $(subst /, ,$(dir $(1))))
endef

PUBLIC?=0
ifeq ($(PUBLIC),1)
	PUBLIC="--public"
else
	PUBLIC=
endif

ALL_REGIONS := $(shell ./aws_regions.sh)
OUT := out

ALL_HA_BYOL := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/ha_byol.ami)
ALL_HA_MP := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/ha_mp.ami)
ALL_AS_BYOL := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/as_byol.ami)
ALL_AS_MP := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/as_mp.ami)
ALL_EGW := $(foreach region,$(ALL_REGIONS),$(OUT)/$(region)/egw.ami)

Q=
ECHO=$(Q)echo

.PHONY: enforce_clean
enforce_clean:
	rm -rf $(OUT)

-include enforce_clean

MAKEFLAGS += --jobs=100

all: $(OUT)/standalone.map $(OUT)/autoscaling.map $(OUT)/egw.map

$(OUT)/standalone.map: $(ALL_HA_BYOL) $(ALL_HA_MP)

	#Merge hashes:
	#jq -s ".[0] * .[1]" a b

	#Gen single ami region map:
	#jq -s add

	$(Q)cat $^ > $@

$(OUT)/autoscaling.map: $(ALL_AS_BYOL) $(ALL_AS_MP)
	$(Q)cat $^ > $@

$(OUT)/egw.map: $(ALL_EGW)
	./json_builder.sh EGW egw.ami | jq -s add > $@

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
	echo $@
	$(Q)mkdir -p $(dir $@)
	./ami_dumper.sh --region $(call get_region,$@) $(PUBLIC) --out $@


# Don't remove intermediate files
.PRECIOUS: %/aws.dump

.PHONY: %/aws.dump
