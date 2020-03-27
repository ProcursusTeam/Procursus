ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LIBSSH2_VERSION := 1.9.0
DEB_LIBSSH2_V   ?= $(LIBSSH2_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libssh2/.build_complete),)
libssh2:
	@echo "Using previously built libssh2."
else
libssh2: setup libressl
	cd $(BUILD_WORK)/libssh2 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug \
		--disable-dependency-tracking \
		--with-libz
	$(MAKE) -C $(BUILD_WORK)/libssh2
	$(MAKE) -C $(BUILD_WORK)/libssh2 install \
		DESTDIR="$(BUILD_STAGE)/libssh2"
	touch $(BUILD_WORK)/libssh2/.build_complete
endif

libssh2-package: libssh2-stage
	# libssh2.mk Package Structure
	rm -rf $(BUILD_DIST)/libssh2
	mkdir -p $(BUILD_DIST)/libssh2
	
	# libssh2.mk Prep libssh2
	$(FAKEROOT) cp -a $(BUILD_STAGE)/libssh2/usr $(BUILD_DIST)/libssh2
	
	# libssh2.mk Sign
	$(call SIGN,libssh2,general.xml)
	
	# libssh2.mk Make .debs
	$(call PACK,libssh2,DEB_LIBSSH2_V)
	
	# libssh2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libssh2

.PHONY: libssh2 libssh2-package
