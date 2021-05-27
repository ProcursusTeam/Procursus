ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += axel
AXEL_VERSION := 2.17.10
DEB_AXEL_V   ?= $(AXEL_VERSION)

axel-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/axel-download-accelerator/axel/releases/download/v$(AXEL_VERSION)/axel-$(AXEL_VERSION).tar.xz
	$(call EXTRACT_TAR,axel-$(AXEL_VERSION).tar.xz,axel-$(AXEL_VERSION),axel)

ifneq ($(wildcard $(BUILD_WORK)/axel/.build_complete),)
axel:
	@echo "Using previously built axel."
else
axel: axel-setup gettext openssl
	cd $(BUILD_WORK)/axel && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/axel install \
		DESTDIR="$(BUILD_STAGE)/axel"
	touch $(BUILD_WORK)/axel/.build_complete
endif

axel-package: axel-stage
	# axel.mk Package Structure
	rm -rf $(BUILD_DIST)/axel

	# axel.mk Prep axel
	cp -a $(BUILD_STAGE)/axel $(BUILD_DIST)

	# axel.mk Sign
	$(call SIGN,axel,general.xml)

	# axel.mk Make .debs
	$(call PACK,axel,DEB_AXEL_V)

	# axel.mk Build cleanup
	rm -rf $(BUILD_DIST)/axel

.PHONY: axel axel-package
