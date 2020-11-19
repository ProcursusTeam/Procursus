ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += ninja
NINJA_VERSION := 1.10.0
DEB_NINJA_V   ?= $(NINJA_VERSION)

ninja-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/ninja-$(NINJA_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/ninja-$(NINJA_VERSION).tar.gz \
			https://github.com/ninja-build/ninja/archive/v$(NINJA_VERSION).tar.gz
	$(call EXTRACT_TAR,ninja-$(NINJA_VERSION).tar.gz,ninja-$(NINJA_VERSION),ninja)
	mkdir -p $(BUILD_WORK)/ninja/build $(BUILD_STAGE)/ninja/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/ninja/.build_complete),)
ninja:
	@echo "Using previously built ninja."
else
ninja: ninja-setup
	cd $(BUILD_WORK)/ninja/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_OSX_ARCHITECTURES="$(ARCHES)" \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		..
	+$(MAKE) -C $(BUILD_WORK)/ninja/build
	cp $(BUILD_WORK)/ninja/build/ninja $(BUILD_STAGE)/ninja/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	touch $(BUILD_WORK)/ninja/.build_complete
endif

ninja-package: ninja-stage
	# ninja.mk Package Structure
	rm -rf $(BUILD_DIST)/ninja
	mkdir -p $(BUILD_DIST)/ninja
	
	# ninja.mk Prep ninja
	cp -a $(BUILD_STAGE)/ninja $(BUILD_DIST)
	
	# ninja.mk Sign
	$(call SIGN,ninja,general.xml)
	
	# ninja.mk Make .debs
	$(call PACK,ninja,DEB_NINJA_V)
	
	# ninja.mk Build cleanup
	rm -rf $(BUILD_DIST)/ninja

.PHONY: ninja ninja-package
