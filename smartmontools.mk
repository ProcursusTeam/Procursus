ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += smartmontools 
SMARTMONTOOLS_VERSION  := 7.2
DEB_SMARTMONTOOLS_V    ?= $(SMARTMONTOOLS_VERSION)

smartmontools-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://managedway.dl.sourceforge.net/project/smartmontools/smartmontools/$(SMARTMONTOOLS_VERSION)/smartmontools-$(SMARTMONTOOLS_VERSION).tar.gz
	$(call EXTRACT_TAR,smartmontools-$(SMARTMONTOOLS_VERSION).tar.gz,smartmontools-$(SMARTMONTOOLS_VERSION),smartmontools)

ifneq ($(wildcard $(BUILD_WORK)/smartmontools/.build_complete),)
smartmontools:
	@echo "Using previously built smartmontools."
else
smartmontools: smartmontools-setup
	cd $(BUILD_WORK)/smartmontools && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-savestates \
		--with-attributelog
	+$(MAKE) -C $(BUILD_WORK)/smartmontools
	+$(MAKE) -C $(BUILD_WORK)/smartmontools install \
		DESTDIR=$(BUILD_STAGE)/smartmontools
	touch $(BUILD_WORK)/smartmontools/.build_complete
endif

smartmontools-package: smartmontools-stage
	# smartmontools.mk Package Structure
	rm -rf $(BUILD_DIST)/smartmontools
	
	# smartmontools.mk Prep smartmontools
	cp -a $(BUILD_STAGE)/smartmontools/* $(BUILD_DIST)/smartmontools/
	
	# smartmontools.mk Sign
	$(call SIGN,smartmontools,apfs.xml)
	
	# smartmontools.mk Make .debs
	$(call PACK,smartmontools,DEB_SMARTMONTOOLS_V)
	
	# smartmontools.mk Build cleanup
	rm -rf $(BUILD_DIST)/smartmontools

.PHONY: smartmontools smartmontools-package
