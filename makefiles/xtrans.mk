ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xtrans
XTRANS_VERSION := 1.4.0
DEB_XTRANS_V   ?= $(XTRANS_VERSION)

xtrans-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/xtrans-$(XTRANS_VERSION).tar.bz2
	$(call EXTRACT_TAR,xtrans-$(XTRANS_VERSION).tar.bz2,xtrans-$(XTRANS_VERSION),xtrans)
	$(SED) -i 's|# include <sys/stropts.h>|# include <sys/ioctl.h>|' $(BUILD_WORK)/xtrans/Xtranslcl.c

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
		DESTDIR="$(BUILD_STAGE)/xtrans"
	+$(MAKE) -C $(BUILD_WORK)/xtrans install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/xtrans/.build_complete
endif

xtrans-package: xtrans-stage
	# xtrans.mk Package Structure
	rm -rf $(BUILD_DIST)/xtrans-dev
	mkdir -p $(BUILD_DIST)/xtrans-dev

	# xtrans.mk Prep xtrans-dev
	cp -a $(BUILD_STAGE)/xtrans/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/xtrans-dev

	# xtrans.mk Make .debs
	$(call PACK,xtrans-dev,DEB_XTRANS_V)

	# xtrans.mk Build cleanup
	rm -rf $(BUILD_DIST)/xtrans-dev

.PHONY: xtrans xtrans-package