ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xlsclients
XLSCLIENTS_VERSION := 1.1.4
DEB_XLSCLIENTS_V   ?= $(XLSCLIENTS_VERSION)

xlsclients-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/app/xlsclients-$(XLSCLIENTS_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xlsclients-$(XLSCLIENTS_VERSION).tar.gz)
	$(call EXTRACT_TAR,xlsclients-$(XLSCLIENTS_VERSION).tar.gz,xlsclients-$(XLSCLIENTS_VERSION),xlsclients)

ifneq ($(wildcard $(BUILD_WORK)/xlsclients/.build_complete),)
xlsclients:
	@echo "Using previously built xlsclients."
else
xlsclients: xlsclients-setup libx11 libxcb
	cd $(BUILD_WORK)/xlsclients && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xlsclients
	+$(MAKE) -C $(BUILD_WORK)/xlsclients install \
		DESTDIR=$(BUILD_STAGE)/xlsclients
	touch $(BUILD_WORK)/xlsclients/.build_complete
endif

xlsclients-package: xlsclients-stage
	# xlsclients.mk Package Structure
	rm -rf $(BUILD_DIST)/xlsclients

	# xlsclients.mk Prep xlsclients
	cp -a $(BUILD_STAGE)/xlsclients $(BUILD_DIST)

	# xlsclients.mk Sign
	$(call SIGN,xlsclients,general.xml)

	# xlsclients.mk Make .debs
	$(call PACK,xlsclients,DEB_XLSCLIENTS_V)

	# xlsclients.mk Build cleanup
	rm -rf $(BUILD_DIST)/xlsclients

.PHONY: xlsclients xlsclients-package
