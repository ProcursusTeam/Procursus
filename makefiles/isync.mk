ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += isync
ISYNC_VERSION := 1.4.3
DEB_ISYNC_V   ?= $(ISYNC_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ISYNC_CONFIGURE_ARGS := --without-macos-keychain
endif

isync-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://downloads.sourceforge.net/sourceforge/isync/isync-$(ISYNC_VERSION).tar.gz
	$(call EXTRACT_TAR,isync-$(ISYNC_VERSION).tar.gz,isync-$(ISYNC_VERSION),isync)

ifneq ($(wildcard $(BUILD_WORK)/isync/.build_complete),)
isync:
	@echo "Using previously built isync."
else
isync: isync-setup openssl
	cd $(BUILD_WORK)/isync && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-ssl=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(ISYNC_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/isync
	+$(MAKE) -C $(BUILD_WORK)/isync install \
		DESTDIR=$(BUILD_STAGE)/isync
	$(call AFTER_BUILD)
endif

isync-package: isync-stage
	# isync.mk Package Structure
	rm -rf $(BUILD_DIST)/isync
	
	# isync.mk Prep isync
	cp -a $(BUILD_STAGE)/isync $(BUILD_DIST)
	
	# isync.mk Sign
	$(call SIGN,isync,general.xml)
	
	# isync.mk Make .debs
	$(call PACK,isync,DEB_ISYNC_V)
	
	# isync.mk Build cleanup
	rm -rf $(BUILD_DIST)/isync

.PHONY: isync isync-package
