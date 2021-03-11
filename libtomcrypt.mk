ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPPROJECTS        += libtomcrypt
LIBTOMCRYPT_VERSION := 1.18.2
DEB_LIBTOMCRYPT_V   ?= $(LIBTOMCRYPT_VERSION)

libtomcrypt-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libtom/libtomcrypt/releases/download/v$(LIBTOMCRYPT_VERSION)/crypt-$(LIBTOMCRYPT_VERSION).tar.xz
	$(call EXTRACT_TAR,crypt-$(LIBTOMCRYPT_VERSION).tar.xz,libtomcrypt-$(LIBTOMCRYPT_VERSION),libtomcrypt)
	mkdir -p $(BUILD_WORK)/libtomcrypt/libtool
	echo -e "AC_INIT([dummy],[1.0])\n\
LT_INIT\n\
AC_PROG_LIBTOOL\n\
AC_OUTPUT" > $(BUILD_WORK)/libtomcrypt/libtool/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libtomcrypt/.build_complete),)
libtomcrypt:
	@echo "Using previously built libtomcrypt."
else
libtomcrypt: libtomcrypt-setup libgmp10 libtommath
	cd $(BUILD_WORK)/libtomcrypt/libtool && LIBTOOLIZE="$(LIBTOOLIZE) -i" autoreconf -fi
	cd $(BUILD_WORK)/libtomcrypt/libtool && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE)
	+$(MAKE) -C $(BUILD_WORK)/libtomcrypt -f makefile.shared \
		EXTRALIBS="-lgmp -ltommath" \
		LIBTOOL="$(BUILD_WORK)/libtommath/libtool/libtool" \
		CFLAGS="$(CFLAGS) -DGMP_DESC -DLTM_DESC -DUSE_LTM"
	+$(MAKE) -C $(BUILD_WORK)/libtomcrypt -f makefile.shared install \
		PREFIX="/usr" \
		DESTDIR="$(BUILD_STAGE)/libtomcrypt"
	+$(MAKE) -C $(BUILD_WORK)/libtomcrypt -f makefile.shared install \
		PREFIX="/usr" \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libtomcrypt/.build_complete
endif

libtomcrypt-package: libtomcrypt-stage
	# libtomcrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/libtomcrypt{1,-dev}
	mkdir -p $(BUILD_DIST)/libtomcrypt{1,-dev}/usr/lib
	
	# libtomcrypt.mk Prep libtomcrypt
	cp -a $(BUILD_STAGE)/libtomcrypt/usr/lib/libtomcrypt.1.dylib $(BUILD_DIST)/libtomcrypt1/usr/lib
	cp -a $(BUILD_STAGE)/libtomcrypt/usr/include $(BUILD_DIST)/libtomcrypt-dev/usr
	cp -a $(BUILD_STAGE)/libtomcrypt/usr/lib/{libtomcrypt.{a,dylib},pkgconfig} $(BUILD_DIST)/libtomcrypt-dev/usr/lib
	
	# libtomcrypt.mk Sign
	$(call SIGN,libtomcrypt1,general.xml)
	
	# libtomcrypt.mk Make .debs
	$(call PACK,libtomcrypt1,DEB_LIBTOMCRYPT_V)
	$(call PACK,libtomcrypt-dev,DEB_LIBTOMCRYPT_V)
	
	# libtomcrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtomcrypt{1,-dev}

.PHONY: libtomcrypt libtomcrypt-package
