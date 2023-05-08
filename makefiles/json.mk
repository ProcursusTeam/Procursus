ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += json
JSON_VERSION := 3.11.2
DEB_JSON_V   ?= $(JSON_VERSION)

json-setup: setup
	$(call GITHUB_ARCHIVE,nlohmann,json,$(JSON_VERSION),v$(JSON_VERSION))
	$(call EXTRACT_TAR,json-$(JSON_VERSION).tar.gz,json-$(JSON_VERSION),json)
	mkdir -p $(BUILD_WORK)/json/build

ifneq ($(wildcard $(BUILD_WORK)/json/.build_complete),)
json:
	@echo "Using previously built json."
else
json: json-setup
	cd $(BUILD_WORK)/json/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/json/build
	+$(MAKE) -C $(BUILD_WORK)/json/build install \
		DESTDIR="$(BUILD_STAGE)/json"
	$(call AFTER_BUILD)
endif

json-package: json-stage
	# json.mk Package Structure
	rm -rf $(BUILD_DIST)/json

	# json.mk Prep json
	cp -a $(BUILD_STAGE)/json $(BUILD_DIST)

	# json.mk Sign
	$(call SIGN,json,general.xml)

	# json.mk Make .debs
	$(call PACK,json,DEB_JSON_V)

	# json.mk Build cleanup
	rm -rf $(BUILD_DIST)/json

.PHONY: json json-package
