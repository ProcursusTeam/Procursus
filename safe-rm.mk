ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += safe-rm
SAFE-RM_VERSION := 1.1.0
DEB_SAFE-RM_V   ?= $(SAFE-RM_VERSION)

safe-rm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE)  https://launchpad.net/safe-rm/trunk/$(SAFE-RM_VERSION)/+download/safe-rm-$(SAFE-RM_VERSION).tar.gz
	$(call EXTRACT_TAR,safe-rm-$(SAFE-RM_VERSION).tar.gz,safe-rm-$(SAFE-RM_VERSION),safe-rm)

ifneq ($(wildcard $(BUILD_WORK)/safe-rm/.build_complete),)
safe-rm:
	@echo "Using previously built safe-rm."
else
safe-rm: safe-rm-setup 
	cd $(BUILD_WORK)/safe-rm && SDKROOT="$(TARGET_SYSROOT)" \
	PKG_CONFIG="$(RUST_TARGET)-pkg-config" cargo \
		build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/safe-rm/target/$(RUST_TARGET)/release/safe-rm \
		$(BUILD_STAGE)/safe-rm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/safe-rm
	touch $(BUILD_WORK)/safe-rm/.build_complete
endif

safe-rm-package: safe-rm-stage
	# safe-rm.mk Package Structure
	rm -rf $(BUILD_DIST)/safe-rm
	
	# safe-rm.mk Prep safe-rm
	cp -a $(BUILD_STAGE)/safe-rm/usr/bin/safe-rm $(BUILD_DIST)
	
	# safe-rm.mk Sign
	$(call SIGN,safe-rm,general.xml)
	
	# safe-rm.mk Make .debs
	$(call PACK,safe-rm,DEB_SAFE-RM_V)
	
	# safe-rm.mk Build cleanup
	rm -rf $(BUILD_DIST)/safe-rm

.PHONY: safe-rm safe-rm-package
