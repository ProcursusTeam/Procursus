ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xtrans
XTRANS_VERSION := 1.5.0
DEB_XTRANS_V   ?= $(XTRANS_VERSION)

xtrans-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.x.org/archive/individual/lib/xtrans-$(XTRANS_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,xtrans-$(XTRANS_VERSION).tar.xz)
	$(call EXTRACT_TAR,xtrans-$(XTRANS_VERSION).tar.xz,xtrans-$(XTRANS_VERSION),xtrans)
	sed -i 's|# include <stropts.h>|# include <sys/ioctl.h>|' $(BUILD_WORK)/xtrans/Xtranslcl.c

ifneq ($(wildcard $(BUILD_WORK)/xtrans/.build_complete),)
xtrans:
	@echo "Using previously built xtrans."
else
xtrans: xtrans-setup
	cd $(BUILD_WORK)/xtrans && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-docs=no
	+$(MAKE) -C $(BUILD_WORK)/xtrans
	+$(MAKE) -C $(BUILD_WORK)/xtrans install \
		DESTDIR="$(BUILD_STAGE)/xtrans-dev"
	$(call AFTER_BUILD,copy)
endif

xtrans-package: xtrans-stage
	# xtrans.mk Package Structure
	rm -rf $(BUILD_DIST)/xtrans-dev

	# xtrans.mk Prep xtrans-dev
	cp -a $(BUILD_STAGE)/xtrans-dev $(BUILD_DIST)

	# xtrans.mk Make .debs
	$(call PACK,xtrans-dev,DEB_XTRANS_V)

	# xtrans.mk Build cleanup
	rm -rf $(BUILD_DIST)/xtrans-dev

.PHONY: xtrans xtrans-package
