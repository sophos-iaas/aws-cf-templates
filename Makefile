
## Configuration
VERSION = 9.370
AUTOSCALING_ARGS = --BYOL 3kn396xknha6uumomjcubi57w --Hourly 9b24287dgv39qtltt9nqvp9kx
HA_ARGS = --BYOL 2xxxjwpanvt6wvbuy0bzrqed7 --Hourly 9xg6czodp2h82gs0tuc1sfhsn

## file sets
ha_regionmap = tmp/ha_regionmap.json
autoscaling_regionmap = tmp/autoscaling_regionmap.json
versiondir = templates/conversion/$(VERSION)

templates := $(addprefix templates/, $(patsubst %.json,%.template,$(notdir $(wildcard src/*.json))))
conversion_templates := $(addprefix templates/conversion/$(VERSION)/, $(patsubst %.json,%.template,$(notdir $(wildcard src/conversion/*.json))))


all: $(autoscaling_regionmap) $(ha_regionmap) $(versiondir) $(templates) $(conversion_templates)

#tmp dir is not in git and empty. Must be created if it does not exist yet
tmp:
	@mkdir $@

# Always rebuild region maps
$(ha_regionmap): FORCE tmp
	@echo Building HA regionmap
	@./bin/fetch_regionmap $(HA_ARGS) --out $@

$(autoscaling_regionmap): FORCE tmp
	@echo Building Autoscaling regionmap
	@./bin/fetch_regionmap $(AUTOSCALING_ARGS) --out $@

# Create new version directory if one for current version does not exist
$(versiondir):
	@echo Creating new conversion release directory
	@mkdir $@
	@ln -f -s -r $@ templates/conversion/current

# Overwrite autoscaling target to use autoscaling region map
templates/autoscaling_waf.template: src/autoscaling_waf.json $(autoscaling_regionmap)
	@echo building $@
	@./bin/build_template --in $< --regionmap $(autoscaling_regionmap) --out $@

templates/%.template: src/%.json $(ha_regionmap)
	@echo building $@
	@./bin/build_template --in $< --regionmap $(ha_regionmap) --out $@

# Overwrite autoscaling target to use autoscaling region map
templates/conversion/$(VERSION)/autoscaling.template: src/conversion/autoscaling.json $(autoscaling_regionmap)
	@echo building $@
	@./bin/build_template --in $< --regionmap $(autoscaling_regionmap) --out $@

templates/conversion/$(VERSION)/%.template: src/conversion/%.json $(ha_regionmap)
	@echo building $@
	@./bin/build_template --in $< --regionmap $(ha_regionmap) --out $@

FORCE:
