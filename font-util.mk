ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += font-util
FONTUTIL_VERSION := 1.3.2
DEB_FONTUTIL_V   ?= $(FONTUTIL_VERSION)

font-util-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive//individual/font/font-util-$(FONTUTIL_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,font-util-$(FONTUTIL_VERSION).tar.gz)
	$(call EXTRACT_TAR,font-util-$(FONTUTIL_VERSION).tar.gz,font-util-$(FONTUTIL_VERSION),font-util)

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
	rm -rf $(BUILD_DIST)/xfonts-utils
	
# font-util.mk Prep font-util
	cp -a $(BUILD_STAGE)/font-util $(BUILD_DIST)/xfonts-utils
	
# font-util.mk Sign
	$(call SIGN,xfonts-utils,general.xml)
	
# font-util.mk Make .debs
	$(call PACK,xfonts-utils,DEB_FONTUTIL_V)
	
# font-util.mk Build cleanup
	rm -rf $(BUILD_DIST)/xfonts-utils

.PHONY: font-util font-util-package
