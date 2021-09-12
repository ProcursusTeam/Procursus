ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += xkbcomp
XKBCOMP_VERSION := 1.4.5
DEB_XKBCOMP_V   ?= $(XKBCOMP_VERSION)

xkbcomp-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/app/xkbcomp-$(XKBCOMP_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xkbcomp-$(XKBCOMP_VERSION).tar.gz)
	$(call EXTRACT_TAR,xkbcomp-$(XKBCOMP_VERSION).tar.gz,xkbcomp-$(XKBCOMP_VERSION),xkbcomp)

ifneq ($(wildcard $(BUILD_WORK)/xkbcomp/.build_complete),)
xkbcomp:
	@echo "Using previously built xkbcomp."
else
xkbcomp: xkbcomp-setup libx11 xorgproto libxkbfile
	$(call CONFIGURE_MAKE_INSTALL)
	$(call AFTER_BUILD)
endif

xkbcomp-package: xkbcomp-stage
	# xkbcomp.mk Package Structure
	rm -rf $(BUILD_DIST)/xkbcomp

	# xkbcomp.mk Prep xkbcomp
	cp -a $(BUILD_STAGE)/xkbcomp $(BUILD_DIST)

	# xkbcomp.mk Sign
	$(call SIGN,xkbcomp,general.xml)

	# xkbcomp.mk Make .debs
	$(call PACK,xkbcomp,DEB_XKBCOMP_V)

	# xkbcomp.mk Build cleanup
	rm -rf $(BUILD_DIST)/xkbcomp

.PHONY: xkbcomp xkbcomp-package
