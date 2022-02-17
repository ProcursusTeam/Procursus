ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xtrans
XTRANS_VERSION := 1.4.0
DEB_XTRANS_V   ?= $(XTRANS_VERSION)-1

xtrans-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/xtrans-$(XTRANS_VERSION).tar.bz2
	$(call EXTRACT_TAR,xtrans-$(XTRANS_VERSION).tar.bz2,xtrans-$(XTRANS_VERSION),xtrans)
	sed -i 's|# include <sys/stropts.h>|# include <sys/ioctl.h>|' $(BUILD_WORK)/xtrans/Xtranslcl.c

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
	$(call AFTER_BUILD,copy)
endif

xtrans-package: xtrans-stage
	# xtrans.mk Package Structure
	rm -rf $(BUILD_DIST)/xtrans-dev
	mkdir -p $(BUILD_DIST)/xtrans-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xtrans.mk Prep xtrans-dev
	cp -a $(BUILD_STAGE)/xtrans/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/ $(BUILD_DIST)/xtrans-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xtrans.mk Make .debs
	$(call PACK,xtrans-dev,DEB_XTRANS_V)

	# xtrans.mk Build cleanup
	rm -rf $(BUILD_DIST)/xtrans-dev

.PHONY: xtrans xtrans-package
