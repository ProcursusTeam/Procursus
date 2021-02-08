ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += expat
EXPAT_VERSION  := 2.2.10
EXPAT_FORMAT_V := 2_2_10
DEB_EXPAT_V    ?= $(EXPAT_VERSION)

expat-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libexpat/libexpat/releases/download/R_$(EXPAT_FORMAT_V)/expat-$(EXPAT_VERSION).tar.xz
	$(call EXTRACT_TAR,expat-$(EXPAT_VERSION).tar.xz,expat-$(EXPAT_VERSION),expat)

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1700 ] && echo 1),1)
expat:
	@echo "Expat is not needed on CFVER 1700+"
else ifneq ($(wildcard $(BUILD_WORK)/expat/.build_complete),)
expat:
	@echo "Using previously built expat."
else
expat: expat-setup
	cd $(BUILD_WORK)/expat && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/expat
	+$(MAKE) -C $(BUILD_WORK)/expat install \
		DESTDIR=$(BUILD_STAGE)/expat
	+$(MAKE) -C $(BUILD_WORK)/expat install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/expat/.build_complete
endif

expat-package: expat-stage
	# expat.mk Package Structure
	rm -rf $(BUILD_DIST)/{expat,libexpat1{,-dev}}
	mkdir -p $(BUILD_DIST)/expat/usr/bin \
		$(BUILD_DIST)/libexpat1{,-dev}/usr/lib
	
	# expat.mk Prep expat
	cp -a $(BUILD_STAGE)/expat/usr/bin/xmlwf $(BUILD_DIST)/expat/usr/bin
	
	# expat.mk Prep libexpat1
	cp -a $(BUILD_STAGE)/expat/usr/lib/libexpat.1*.dylib $(BUILD_DIST)/libexpat1/usr/lib
	
	# expat.mk Prep libexpat1-dev
	cp -a $(BUILD_STAGE)/expat/usr/lib/{libexpat.{a,dylib},pkgconfig} $(BUILD_DIST)/libexpat1-dev/usr/lib
	cp -a $(BUILD_STAGE)/expat/usr/include $(BUILD_DIST)/libexpat1-dev/usr/
	
	# expat.mk Sign
	$(call SIGN,expat,general.xml)
	$(call SIGN,libexpat1,general.xml)
	
	# expat.mk Make .debs
	$(call PACK,expat,DEB_EXPAT_V)
	$(call PACK,libexpat1,DEB_EXPAT_V)
	$(call PACK,libexpat1-dev,DEB_EXPAT_V)
	
	# expat.mk Build cleanup
	rm -rf $(BUILD_DIST)/{expat,libexpat1{,-dev}}

.PHONY: expat expat-package
