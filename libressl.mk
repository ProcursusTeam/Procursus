ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LIBRESSL_VERSION := 3.0.2
DEB_LIBRESSL_V   ?= $(LIBRESSL_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libressl/.build_complete),)
libressl:
	@echo "Using previously built libressl."
else
libressl: setup
	cd $(BUILD_WORK)/libressl && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-openssldir=/etc/ssl \
		--sysconfdir=/etc
	$(MAKE) -C $(BUILD_WORK)/libressl
	$(MAKE) -C $(BUILD_WORK)/libressl install \
		DESTDIR=$(BUILD_STAGE)/libressl
	$(MAKE) -C $(BUILD_WORK)/libressl install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libressl/.build_complete
endif

libressl-package: libressl-stage
	# libressl.mk Package Structure
	rm -rf $(BUILD_DIST)/libressl
	mkdir -p $(BUILD_DIST)/libressl
	
	# libressl.mk Prep libressl
	$(FAKEROOT) cp -a $(BUILD_STAGE)/libressl/{etc,usr} $(BUILD_DIST)/libressl
	
	# libressl.mk Sign
	$(call SIGN,libressl,general.xml)
	
	# libressl.mk Make .debs
	$(call PACK,libressl,DEB_LIBRESSL_V)
	
	# libressl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libressl

.PHONY: libressl libressl-package
