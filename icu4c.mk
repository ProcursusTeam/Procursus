ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += icu4c
ICU_VERSION  := 68.1
DEB_ICU_V    ?= $(ICU_VERSION)

icu4c-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/icu4c-$(ICU_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/icu4c-$(ICU_VERSION).tar.gz \
			https://github.com/unicode-org/icu/releases/download/release-$(shell echo $(ICU_VERSION) | $(SED) 's/\./-/')/icu4c-$(shell echo $(ICU_VERSION) | $(SED) 's/\./_/')-src.tgz
	$(call EXTRACT_TAR,icu4c-$(ICU_VERSION).tar.gz,icu,icu4c)
	mkdir -p $(BUILD_WORK)/icu4c/host

ifneq ($(wildcard $(BUILD_WORK)/icu4c/.build_complete),)
icu4c:
	@echo "Using previously built icu4c."
else
icu4c: icu4c-setup
	cd $(BUILD_WORK)/icu4c/host && unset CC CXX CPP CFLAGS CPPFLAGS CXXFLAGS LDFLAGS RANLIB AR; \
		../source/configure; \
		$(MAKE) -C $(BUILD_WORK)/icu4c/host
	cd $(BUILD_WORK)/icu4c/source && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--with-cross-build=$(BUILD_WORK)/icu4c/host \
		--prefix=/usr \
		--disable-samples \
		--disable-tests
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_STAGE)/icu4c
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/icu4c/.build_complete
endif

icu4c-package: icu4c-stage
	# icu4c.mk Package Structure
	rm -rf $(BUILD_DIST)/libicu{68,-dev} \
		$(BUILD_DIST)/icu-devtools
	mkdir -p $(BUILD_DIST)/libicu{68,-dev}/usr/lib \
		$(BUILD_DIST)/libicu-dev/usr/share \
		$(BUILD_DIST)/icu-devtools/usr
	
	# icu4c.mk Prep libicu68
	cp -a $(BUILD_STAGE)/icu4c/usr/lib/libicu*.68*.dylib $(BUILD_DIST)/libicu68/usr/lib
	
	# icu4c.mk Prep libicu-dev
	cp -a $(BUILD_STAGE)/icu4c/usr/lib/libicu{data,i18n,io,test,tu,uc}.dylib $(BUILD_DIST)/libicu-dev/usr/lib
	cp -a $(BUILD_STAGE)/icu4c/usr/lib/{pkgconfig,icu} $(BUILD_DIST)/libicu-dev/usr/lib
	cp -a $(BUILD_STAGE)/icu4c/usr/share/icu $(BUILD_DIST)/libicu-dev/usr/share
	
	# icu4c.mk Prep icu-devtools 
	cp -a $(BUILD_STAGE)/icu4c/usr/{sbin,bin,share} $(BUILD_DIST)/icu-devtools/usr
	rm -f $(BUILD_DIST)/icu-devtools/usr/bin/icu-config
	rm -f $(BUILD_DIST)/icu-devtools/usr/share/man/man1/icu-config.1
	rm -rf $(BUILD_DIST)/icu-devtools/usr/share/icu
	
	# icu4c.mk Sign
	$(call SIGN,libicu68,general.xml)
	$(call SIGN,icu-devtools,general.xml)
	
	# icu4c.mk Make .debs
	$(call PACK,libicu68,DEB_ICU_V)
	$(call PACK,libicu-dev,DEB_ICU_V)
	$(call PACK,icu-devtools,DEB_ICU_V)
	
	# icu4c.mk Build cleanup
	rm -rf $(BUILD_DIST)/libicu{68,-dev} \
		$(BUILD_DIST)/icu-devtools

.PHONY: icu4c icu4c-package
