ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += wabt
WABT_VERSION := 1.0.23
DEB_WABT_V   ?= $(WABT_VERSION)

wabt-setup: setup
	$(call GIT_CLONE,https://github.com/WebAssembly/wabt.git,$(WABT_VERSION),wabt)
	mkdir -p $(BUILD_WORK)/wabt/build

ifneq ($(wildcard $(BUILD_WORK)/wabt/.build_complete),)
wabt:
	@echo "Using previously built wabt."
else
wabt: wabt-setup
	cd $(BUILD_WORK)/wabt/build && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_TESTS=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/wabt/build
	+$(MAKE) -C $(BUILD_WORK)/wabt/build install \
		DESTDIR="$(BUILD_STAGE)/wabt"
	touch $(BUILD_WORK)/wabt/.build_complete
endif

wabt-package: wabt-stage
	# wabt.mk Package Structure
	rm -rf $(BUILD_DIST)/wabt
	
	# wabt.mk Prep wabt
	cp -a $(BUILD_STAGE)/wabt $(BUILD_DIST)
	
	# wabt.mk Sign
	$(call SIGN,wabt,general.xml)
	
	# wabt.mk Make .debs
	$(call PACK,wabt,DEB_WABT_V)
	
	# wabt.mk Build cleanup
	rm -rf $(BUILD_DIST)/wabt

.PHONY: wabt wabt-package
