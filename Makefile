## Configuration
VERSION = 9.370
AUTOSCALING_ARGS = --BYOL 3kn396xknha6uumomjcubi57w --Hourly 9b24287dgv39qtltt9nqvp9kx
HA_ARGS = --BYOL 2xxxjwpanvt6wvbuy0bzrqed7 --Hourly 9xg6czodp2h82gs0tuc1sfhsn

## file sets
HA_REGIONMAP = tmp/HA_REGIONMAP.json
AUTOSCALING_REGIONMAP = tmp/AUTOSCALING_REGIONMAP.json
VERSIONDIR = templates/conversion/$(VERSION)

TEMPLATES := $(addprefix templates/, $(patsubst %.json,%.template,$(notdir $(wildcard src/*.json))))
CONVERSION_TEMPLATES := $(addprefix templates/conversion/$(VERSION)/, $(patsubst %.json,%.template,$(notdir $(wildcard src/conversion/*.json))))

## bins
BUNDLE_EXEC = bundle exec
FETCH_REGIONMAP = $(BUNDLE_EXEC) ./bin/fetch_regionmap
BUILD_TEMPLATE = $(BUNDLE_EXEC) ./bin/build_template

all: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(VERSIONDIR) $(TEMPLATES) $(CONVERSION_TEMPLATES)

# Always rebuild region maps
$(HA_REGIONMAP): tmp
	@echo Building HA regionmap
	@$(FETCH_REGIONMAP) $(HA_ARGS) --out $@

$(AUTOSCALING_REGIONMAP): tmp
	@echo Building Autoscaling RegionMap
	@$(FETCH_REGIONMAP) $(AUTOSCALING_ARGS) --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/autoscaling_waf.template: src/autoscaling_waf.json $(AUTOSCALING_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP) --out $@

templates/%.template: src/%.json $(HA_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP) --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/conversion/$(VERSION)/autoscaling.template: src/conversion/autoscaling.json $(AUTOSCALING_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(AUTOSCALING_REGIONMAP) --out $@

templates/conversion/$(VERSION)/%.template: src/conversion/%.json $(HA_REGIONMAP)
	@echo building $@
	@$(BUILD_TEMPLATE) --in $< --regionmap $(HA_REGIONMAP) --out $@

# Create new version directory, if previous doesn't exist
$(VERSIONDIR):
	@echo Creating new conversion release directory
	@mkdir -p $@
	@ln -n -r -s -f $@ templates/conversion/current

#tmp dir is not in git and empty. Must be created if it does not exist yet
tmp:
	@mkdir $@


.PHONY: $(AUTOSCALING_REGIONMAP) $(HA_REGIONMAP) $(VERSIONDIR)
