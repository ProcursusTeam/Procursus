ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += tsschecker
DOWNLOAD           += https://github.com/tihmstar/tsschecker/archive/$(TSSCHECKER_VERSION).tar.gz
TSSCHECKER_VERSION := 304
DEB_TSSCHECKER_V   ?= $(TSSCHECKER_VERSION)

tsschecker-setup: setup
	$(call EXTRACT_TAR,$(TSSCHECKER_VERSION).tar.gz,tsschecker-$(TSSCHECKER_VERSION),tsschecker)

ifneq ($(wildcard $(BUILD_WORK)/tsschecker/.build_complete),)
tsschecker:
	@echo "Using previously built tsschecker."
else
tsschecker: tsschecker-setup curl libplist openssl libfragmentzip libirecovery
	cd $(BUILD_WORK)/tsschecker && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr 
	+$(MAKE) -C $(BUILD_WORK)/tsschecker
	+$(MAKE) -C $(BUILD_WORK)/tsschecker install \
		DESTDIR="$(BUILD_STAGE)/tsschecker"
	touch $(BUILD_WORK)/tsschecker/.build_complete
endif

tsschecker-package: tsschecker-stage
	# tsschecker.mk Package Structure
	rm -rf $(BUILD_DIST)/tsschecker
	mkdir -p $(BUILD_DIST)/tsschecker
	
	# tsschecker.mk Prep tsschecker
	cp -a $(BUILD_STAGE)/tsschecker/usr $(BUILD_DIST)/tsschecker
	
	# tsschecker.mk Sign
	$(call SIGN,tsschecker,general.xml)
	
	# tsschecker.mk Make .debs
	$(call PACK,tsschecker,DEB_TSSCHECKER_V)
	
	# tsschecker.mk Build cleanup
	rm -rf $(BUILD_DIST)/tsschecker

.PHONY: tsschecker tsschecker-package
