ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += font-util
FONT-UTIL_VERSION := 1.3.2
DEB_FONT-UTIL_V   ?= $(FONT-UTIL_VERSION)

font-util-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive//individual/font/font-util-$(FONT-UTIL_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,font-util-$(FONT-UTIL_VERSION).tar.gz)
	$(call EXTRACT_TAR,font-util-$(FONT-UTIL_VERSION).tar.gz,font-util-$(FONT-UTIL_VERSION),font-util)

ifneq ($(wildcard $(BUILD_WORK)/font-util/.build_complete),)
font-util:
	@echo "Using previously built font-util."
else
font-util: font-util-setup
	cd $(BUILD_WORK)/font-util && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/font-util
	+$(MAKE) -C $(BUILD_WORK)/font-util install \
		DESTDIR=$(BUILD_STAGE)/font-util
	+$(MAKE) -C $(BUILD_WORK)/font-util install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-util/.build_complete
endif

font-util-package: font-util-stage
# font-util.mk Package Structure
	rm -rf $(BUILD_DIST)/font-util
	
# font-util.mk Prep font-util
	cp -a $(BUILD_STAGE)/font-util $(BUILD_DIST)
	
# font-util.mk Sign
	$(call SIGN,font-util,general.xml)
	
# font-util.mk Make .debs
	$(call PACK,font-util,DEB_font-util_V)
	
# font-util.mk Build cleanup
	rm -rf $(BUILD_DIST)/font-util

.PHONY: font-util font-util-package
