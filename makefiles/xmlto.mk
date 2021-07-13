ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xmlto
XMLTO_VERSION := 0.0.28
DEB_XMLTO_V   ?= $(XMLTO_VERSION)

xmlto-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://releases.pagure.org/xmlto/xmlto-$(XMLTO_VERSION).tar.bz2 
	$(call EXTRACT_TAR,xmlto-$(XMLTO_VERSION).tar.bz2,xmlto-$(XMLTO_VERSION),xmlto)

ifneq ($(wildcard $(BUILD_WORK)/xmlto/.build_complete),)
xmlto:
	@echo "Using previously built xmlto."
else
xmlto: xmlto-setup
	cd $(BUILD_WORK)/xmlto && GETOPT=ggetopt ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xmlto
	+$(MAKE) -C $(BUILD_WORK)/xmlto install \
		DESTDIR=$(BUILD_STAGE)/xmlto
	touch $(BUILD_WORK)/xmlto/.build_complete
endif

xmlto-package: xmlto-stage
	# xmlto.mk Package Structure
	rm -rf $(BUILD_DIST)/xmlto

	# xmlto.mk Prep xmlto
	cp -a $(BUILD_STAGE)/xmlto $(BUILD_DIST)

	# xmlto.mk Sign
	$(call SIGN,xmlto,general.xml)

	# xmlto.mk Make .debs
	$(call PACK,xmlto,DEB_XMLTO_V)

	# xmlto.mk Build cleanup
	rm -rf $(BUILD_DIST)/xmlto

.PHONY: xmlto xmlto-package
