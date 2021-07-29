ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += socat
SOCAT_VERSION := 1.7.4.1
DEB_SOCAT_V   ?= $(SOCAT_VERSION)

socat-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://www.dest-unreach.org/socat/download/socat-$(SOCAT_VERSION).tar.gz
	$(call EXTRACT_TAR,socat-$(SOCAT_VERSION).tar.gz,socat-$(SOCAT_VERSION),socat)

ifneq ($(wildcard $(BUILD_WORK)/socat/.build_complete),)
socat:
	@echo "Using previously built socat."
else
socat: socat-setup openssl readline
	cd $(BUILD_WORK)/socat && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/socat
	+$(MAKE) -C $(BUILD_WORK)/socat install \
		DESTDIR=$(BUILD_STAGE)/socat
	touch $(BUILD_WORK)/socat/.build_complete
endif

socat-package: socat-stage
	# socat.mk Package Structure
	rm -rf $(BUILD_DIST)/socat

	# socat.mk Prep socat
	cp -a $(BUILD_STAGE)/socat $(BUILD_DIST)

	# socat.mk Sign
	$(call SIGN,socat,general.xml)

	# socat.mk Make .debs
	$(call PACK,socat,DEB_SOCAT_V)

	# socat.mk Build cleanup
	rm -rf $(BUILD_DIST)/socat

.PHONY: socat socat-package
