ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += ddrescue
DDRESCUE_VERSION := 1.25
DEB_DDRESCUE_V   ?= $(DDRESCUE_VERSION)

ddrescue-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://mirror.keystealth.org/gnu/ddrescue/ddrescue-$(DDRESCUE_VERSION).tar.lz
	$(call EXTRACT_TAR,ddrescue-$(DDRESCUE_VERSION).tar.lz,ddrescue-$(DDRESCUE_VERSION),ddrescue)

ifneq ($(wildcard $(BUILD_WORK)/ddrescue/.build_complete),)
ddrescue:
	@echo "Using previously built ddrescue."
else
ddrescue: ddrescue-setup
	cd $(BUILD_WORK)/ddrescue && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/ddrescue
	+$(MAKE) -C $(BUILD_WORK)/ddrescue install \
		DESTDIR=$(BUILD_STAGE)/ddrescue
	touch $(BUILD_WORK)/ddrescue/.build_complete
endif

ddrescue-package: ddrescue-stage
	# ddrescue.mk Package Structure
	rm -rf $(BUILD_DIST)/ddrescue
	
	# ddrescue.mk Prep ddrescue
	cp -a $(BUILD_STAGE)/ddrescue $(BUILD_DIST)
	
	# ddrescue.mk Sign
	$(call SIGN,ddrescue,general.xml)
	
	# ddrescue.mk Make .debs
	$(call PACK,ddrescue,DEB_DDRESCUE_V)
	
	# ddrescue.mk Build cleanup
	rm -rf $(BUILD_DIST)/ddrescue

.PHONY: ddrescue ddrescue-package
