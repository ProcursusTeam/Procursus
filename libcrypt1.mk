ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libcrypt1
LIBCRYPT1_VERSION  := 4.4.16

libcrypt1-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://deb.debian.org/debian/pool/main/libx/libxcrypt/libxcrypt_$(LIBCRYPT1_VERSION).orig.tar.xz
	$(call EXTRACT_TAR,libxcrypt_$(LIBCRYPT1_VERSION).orig.tar.xz,libxcrypt-$(LIBCRYPT1_VERSION),libcrypt1)

ifneq ($(wildcard $(BUILD_WORK)/libcrypt1/.build_complete),)
libcrypt1:
	@echo "Using previously built libcrypt1."
else
libcrypt1: libcrypt1-setup gettext
	+cd $(BUILD_WORK)/libcrypt1 && ./autogen.sh && ./configure \
		--host=$(GNU_HOST_TRIPLE)
	+$(MAKE) -C $(BUILD_WORK)/libcrypt1 \
		CC=$(CC) \
		CFLAGS='$(CFLAGS) -Wall -I.'
	+$(MAKE) -C $(BUILD_WORK)/libcrypt1 install \
		DESTDIR=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/libcrypt1 install \
		DESTDIR=$(BUILD_STAGE)/libcrypt1
	touch $(BUILD_WORK)/libcrypt1/.build_complete
endif

libcrypt1-package: libcrypt1-stage
	# libcrypt1.mk Package Structure
	rm -rf $(BUILD_DIST)/libcrypt1
	mkdir -p $(BUILD_DIST)/libcrypt1
	
	# libcrypt1.mk Prep libcrypt1
	cp -a $(BUILD_STAGE)/libcrypt1/usr $(BUILD_DIST)/libcrypt1
	mkdir -p $(BUILD_DIST)/libcrypt1/usr/share
	
	# libcrypt1.mk Sign
	$(call SIGN,libcrypt1,general.xml)
	
	# libcrypt1.mk Make .debs
	$(call PACK,libcrypt1,LIBCRYPT1_VERSION)
	
	# libcrypt1.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcrypt1

.PHONY: libcrypt1 libcrypt1-package
