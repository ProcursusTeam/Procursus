ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xclip
XCLIP_VERSION := 0.13
DEB_XCLIP_V   ?= $(XCLIP_VERSION)

xclip-setup: setup
	$(call GITHUB_ARCHIVE,astrand,xclip,$(XCLIP_VERSION),$(XCLIP_VERSION))
	$(call EXTRACT_TAR,xclip-$(XCLIP_VERSION).tar.gz,xclip-$(XCLIP_VERSION),xclip)
	mkdir -p $(BUILD_STAGE)/xclip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/xclip/.build_complete),)
xclip:
	@echo "Using previously built xclip."
else
xclip: xclip-setup libxmu
	cd $(BUILD_WORK)/xclip && autoreconf -fi
	cd $(BUILD_WORK)/xclip && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	$(MAKE) -C $(BUILD_WORK)/xclip
	$(MAKE) -C $(BUILD_WORK)/xclip install \
		DESTDIR=$(BUILD_STAGE)/xclip
	touch $(BUILD_WORK)/xclip/.build_complete
endif

xclip-package: xclip-stage
	# xclip.mk Package Structure
	rm -rf $(BUILD_DIST)/xclip

	# xclip.mk Prep xclip
	cp -a $(BUILD_STAGE)/xclip $(BUILD_DIST)

	# xclip.mk Sign
	$(call SIGN,xclip,general.xml)

	# xclip.mk Make .debs
	$(call PACK,xclip,DEB_XCLIP_V)

	# xclip.mk Build cleanup
	rm -rf $(BUILD_DIST)/xclip

.PHONY: xclip xclip-package
