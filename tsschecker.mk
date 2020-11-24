ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += tsschecker
TSSCHECKER_VERSION := 304
DEB_TSSCHECKER_V   ?= $(TSSCHECKER_VERSION)-1

tsschecker-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tihmstar/tsschecker/archive/$(TSSCHECKER_VERSION).tar.gz
	-[ ! -f "$(BUILD_SOURCE)/jssy.tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/jssy.tar.gz https://github.com/tihmstar/jssy/tarball/master
	$(call EXTRACT_TAR,$(TSSCHECKER_VERSION).tar.gz,tsschecker-$(TSSCHECKER_VERSION),tsschecker)
	# so EXTRACT_TAR wont fail
	-$(RMDIR) $(BUILD_WORK)/tsschecker/external/jssy
	$(call EXTRACT_TAR,jssy.tar.gz,tihmstar-jssy-*,tsschecker/external/jssy)
	$(SED) -i 's/libplist /libplist-2.0 /g' $(BUILD_WORK)/tsschecker/configure.ac
	$(SED) -i 's/libirecovery /libirecovery-1.0 /g' $(BUILD_WORK)/tsschecker/configure.ac
	$(SED) -i '/AC_FUNC_MALLOC/d' $(BUILD_WORK)/tsschecker/configure.ac
	$(SED) -i '/AC_FUNC_REALLOC/d' $(BUILD_WORK)/tsschecker/configure.ac


ifneq ($(wildcard $(BUILD_WORK)/tsschecker/.build_complete),)
tsschecker:
	@echo "Using previously built tsschecker."
else
tsschecker: tsschecker-setup libfragmentzip libplist curl libirecovery
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
