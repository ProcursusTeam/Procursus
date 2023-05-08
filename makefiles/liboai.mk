ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += liboai
LIBOAI_VERSION := 3.0.2
DEB_LIBOAI_V   ?= $(LIBOAI_VERSION)

liboai-setup: setup
	$(call GITHUB_ARCHIVE,D7EAD,liboai,$(LIBOAI_VERSION),v$(LIBOAI_VERSION))
	$(call EXTRACT_TAR,liboai-$(LIBOAI_VERSION).tar.gz,liboai-$(LIBOAI_VERSION),liboai)
	mkdir -p $(BUILD_WORK)/liboai/liboai/build
	sed -i 's/CURL CONFIG REQUIRED/CURL REQUIRED/g' $(BUILD_WORK)/liboai/liboai/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/liboai/.build_complete),)
liboai:
	@echo "Using previously built liboai."
else
liboai: liboai-setup json curl
	cd $(BUILD_WORK)/liboai/liboai/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_PREFIX_PATH=$(BUILD_STAGE)/json/usr/share/cmake/nlohmann_json/ \
		-DCMAKE_CURL_INCLUDE_DIRS=$(BUILD_STAGE)/curl/usr/include/ \
		-DBUILD_SHARED_LIBS=true \
		..
	+$(MAKE) -C $(BUILD_WORK)/liboai/liboai/build
	+$(MAKE) -C $(BUILD_WORK)/liboai/liboai/build install \
		DESTDIR="$(BUILD_STAGE)/liboai"
	$(call AFTER_BUILD)
endif

liboai-package: liboai-stage
	# liboai.mk Package Structure
	rm -rf $(BUILD_DIST)/liboai{,-dev}
	mkdir -p $(BUILD_DIST)/liboai{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# liboai.mk Prep liboai
	cp -a $(BUILD_STAGE)/liboai/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liboai.dylib $(BUILD_DIST)/liboai/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# liboai.mk Prep liboai-dev
	cp -a $(BUILD_STAGE)/liboai/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/liboai-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# liboai.mk Sign
	$(call SIGN,liboai,general.xml)

	# liboai.mk Make .debs
	$(call PACK,liboai,DEB_LIBOAI_V)
	$(call PACK,liboai-dev,DEB_LIBOAI_V)

	# liboai.mk Build cleanup
	rm -rf $(BUILD_DIST)/liboai{,-dev}
.PHONY: liboai liboai-package
