ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += smartmontools 
SMARTMONTOOLS_VERSION  := 7.2
DEB_SMARTMONTOOLS_V    ?= $(SMARTMONTOOLS_VERSION)

smartmontools-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://managedway.dl.sourceforge.net/project/smartmontools/smartmontools/7.2/smartmontools-$(SMARTMONTOOLS_VERSION).tar.gz
	$(call EXTRACT_TAR,smartmontools-$(SMARTMONTOOLS_VERSION).tar.gz,smartmontools-$(SMARTMONTOOLS_VERSION),smartmontools)

ifneq ($(wildcard $(BUILD_WORK)/smartmontools/.build_complete),)
smartmontools:
	@echo "Using previously built smartmontools."
else
smartmontools: smartmontools-setup
	cd $(BUILD_WORK)/smartmontools && ./configure -C \
		--with-savestates \
		--with-attributelog \
		$(DEFAULT_CONFIGURE_FLAGS) \
	+$(MAKE) -C $(BUILD_WORK)/smartmontools
	+$(MAKE) -C $(BUILD_WORK)/smartmontools install \
		DESTDIR=$(BUILD_STAGE)/smartmontools
	touch $(BUILD_WORK)/smartmontools/.build_complete
endif

smartmontools-package: smartmontools-stage
	# smartmontools.mk Package Structure
	rm -rf $(BUILD_DIST)/smartmontools
	mkdir -p $(BUILD_DIST)/smartmontools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	# smartmontools.mk Prep smartmontools
	cp -a $(BUILD_STAGE)/smartmontools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/* $(BUILD_DIST)/smartmontools$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	# smartmontools.mk Sign
	$(call SIGN,smartmontools,apfs.xml)
	
	# smartmontools.mk Make .debs
	$(call PACK,smartmontools,DEB_SMARTMONTOOLS_V)
	
	# smartmontools.mk Build cleanup
	rm -rf $(BUILD_DIST)/smartmontools

.PHONY: smartmontools smartmontools-package
