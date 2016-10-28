DEV?=devel

ALL_REGIONS := $(shell ./all_regions.sh)

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
	$(Q)cat $^ > $@

$(OUT)/autoscaling.map: $(ALL_AS_BYOL) $(ALL_AS_MP)
	$(Q)cat $^ > $@

$(OUT)/egw.map: $(ALL_EGW)
	$(Q)cat $^ > $@

%/egw.ami: %/aws.dump
	$(Q)cat $^ > $@

%/ha_byol.ami: %/aws.dump
	$(Q)cat $^ > $@

%/ha_mp.ami: %/aws.dump
	$(Q)cat $^ > $@

%/as_byol.ami: %/aws.dump
	$(Q)cat $^ > $@

%/as_mp.ami: %/aws.dump
	$(Q)cat $^ > $@

%/aws.dump:
	echo $@
	$(Q)mkdir -p $(dir $@)
	$(Q)echo A > $@

# Don't remove intermediate files
.PRECIOUS: %/aws.dump

.PHONY: %/aws.dump
