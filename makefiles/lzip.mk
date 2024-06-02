ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += lzip
LZIP_VERSION  := 1.24
DEB_LZIP_V    ?= $(LZIP_VERSION)

lzip-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),http://download.savannah.gnu.org/releases/lzip/lzip-$(LZIP_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,lzip-$(LZIP_VERSION).tar.gz)
	$(call EXTRACT_TAR,lzip-$(LZIP_VERSION).tar.gz,lzip-$(LZIP_VERSION),lzip)

ifneq ($(wildcard $(BUILD_WORK)/lzip/.build_complete),)
lzip:
	@echo "Using previously built lzip."
else
lzip: lzip-setup
	cd $(BUILD_WORK)/lzip && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CXX=$(CXX) \
		CXXFLAGS="$(CXXFLAGS)" \
		CPPFLAGS="$(CPPFLAGS)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/lzip
	+$(MAKE) -C $(BUILD_WORK)/lzip install -j1 \
		DESTDIR="$(BUILD_STAGE)/lzip"
	$(call AFTER_BUILD,copy)
endif

lzip-package: lzip-stage
	# lzip.mk Package Structure
	rm -rf $(BUILD_DIST)/lzip

	# lzip.mk Prep lzip
	cp -a $(BUILD_STAGE)/lzip $(BUILD_DIST)

	# lzip.mk Sign
	$(call SIGN,lzip,general.xml)

	#lzip.mk Make .debs
	$(call PACK,lzip,DEB_LZIP_V)

	# lzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/lzip

.PHONY: lzip lzip-package
