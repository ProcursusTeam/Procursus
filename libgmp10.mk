ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += libgmp10
GMP_VERSION := 6.2.1
DEB_GMP_V   ?= $(GMP_VERSION)-1

libgmp10-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gmplib.org/download/gmp/gmp-$(GMP_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,gmp-$(GMP_VERSION).tar.xz)
	$(call EXTRACT_TAR,gmp-$(GMP_VERSION).tar.xz,gmp-$(GMP_VERSION),libgmp10)

ifneq ($(wildcard $(BUILD_WORK)/libgmp10/.build_complete),)
libgmp10:
	@echo "Using previously built libgmp10."
else
libgmp10: libgmp10-setup
	cd $(BUILD_WORK)/libgmp10 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-assembly
	+$(MAKE) -C $(BUILD_WORK)/libgmp10
	+$(MAKE) -C $(BUILD_WORK)/libgmp10 install \
		DESTDIR=$(BUILD_STAGE)/libgmp10
	+$(MAKE) -C $(BUILD_WORK)/libgmp10 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgmp10/.build_complete
endif

libgmp10-package: libgmp10-stage
	# libgmp10.mk Package Structure
	rm -rf $(BUILD_DIST)/libgmp{10,-dev}
	mkdir -p $(BUILD_DIST)/libgmp{10,-dev}/usr/lib
	
	# libgmp10.mk Prep libgmp10
	cp -a $(BUILD_STAGE)/libgmp10/usr/lib/libgmp.10.dylib $(BUILD_DIST)/libgmp10/usr/lib
	
	# libgmp10.mk Prep libgmp-dev
	cp -a $(BUILD_STAGE)/libgmp10/usr/lib/{pkgconfig,libgmp.{dylib,a}} $(BUILD_DIST)/libgmp-dev/usr/lib
	cp -a $(BUILD_STAGE)/libgmp10/usr/include $(BUILD_DIST)/libgmp-dev/usr
	
	# libgmp10.mk Sign
	$(call SIGN,libgmp10,general.xml)
	
	# libgmp10.mk Make .debs
	$(call PACK,libgmp10,DEB_GMP_V)
	$(call PACK,libgmp-dev,DEB_GMP_V)
	
	# libgmp10.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgmp{10,-dev}

.PHONY: libgmp10 libgmp10-package
