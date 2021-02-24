ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += nghttp2
NGHTTP2_VERSION := 1.41.0
DEB_NGHTTP2_V   ?= $(NGHTTP2_VERSION)

##### EVALUATE WHETHER THIS NEEDS LAUNCHDAEMONS AT A LATER DATE #####

nghttp2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/nghttp2/nghttp2/releases/download/v$(NGHTTP2_VERSION)/nghttp2-$(NGHTTP2_VERSION).tar.xz
	$(call EXTRACT_TAR,nghttp2-$(NGHTTP2_VERSION).tar.xz,nghttp2-$(NGHTTP2_VERSION),nghttp2)

ifneq ($(wildcard $(BUILD_WORK)/nghttp2/.build_complete),)
nghttp2:
	@echo "Using previously built nghttp2."
else
nghttp2: nghttp2-setup openssl libc-ares libev jansson libjemalloc libevent
	cd $(BUILD_WORK)/nghttp2 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) \
		--disable-dependency-tracking \
		--without-systemd \
		--enable-python-bindings=no \
		LIBXML2_CFLAGS=-I$(TARGET_SYSROOT)/usr/include/libxml2 \
		LIBXML2_LIBS=-lxml2
	+$(MAKE) -C $(BUILD_WORK)/nghttp2
	+$(MAKE) -C $(BUILD_WORK)/nghttp2 install \
		DESTDIR="$(BUILD_STAGE)/nghttp2"
	+$(MAKE) -C $(BUILD_WORK)/nghttp2 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/nghttp2/.build_complete
endif

nghttp2-package: nghttp2-stage
	# nghttp2.mk Package Structure
	rm -rf $(BUILD_DIST)/libnghttp2-{14,dev} $(BUILD_DIST)/nghttp2-{client,proxy,server}
	mkdir -p $(BUILD_DIST)/libnghttp2-{14,dev}/usr/lib \
		$(BUILD_DIST)/nghttp2-{proxy,server,client}/usr/{bin,share/man/man1}
	
	# nghttp2.mk Prep libnghttp2-14
	cp -a $(BUILD_STAGE)/nghttp2/usr/lib/libnghttp2.14.dylib $(BUILD_DIST)/libnghttp2-14/usr/lib
	
	# nghttp2.mk Prep libnghttp2-dev
	cp -a $(BUILD_STAGE)/nghttp2/usr/lib/!(libnghttp2.14.dylib) $(BUILD_DIST)/libnghttp2-dev/usr/lib
	cp -a $(BUILD_STAGE)/nghttp2/usr/include $(BUILD_DIST)/libnghttp2-dev/usr

	# nghttp2.mk Prep nghttp2-proxy
	cp -a $(BUILD_STAGE)/nghttp2/usr/bin/nghttpx $(BUILD_DIST)/nghttp2-proxy/usr/bin
	cp -a $(BUILD_STAGE)/nghttp2/usr/share/man/man1/nghttpx.1 $(BUILD_DIST)/nghttp2-proxy/usr/share/man/man1
	cp -a $(BUILD_STAGE)/nghttp2/usr/share/nghttp2 $(BUILD_DIST)/nghttp2-proxy/usr/share

	# nghttp2.mk Prep nghttp2-server
	cp -a $(BUILD_STAGE)/nghttp2/usr/bin/nghttpd $(BUILD_DIST)/nghttp2-server/usr/bin
	cp -a $(BUILD_STAGE)/nghttp2/usr/share/man/man1/nghttpd.1 $(BUILD_DIST)/nghttp2-server/usr/share/man/man1

	# nghttp2.mk Prep nghttp2-client
	cp -a $(BUILD_STAGE)/nghttp2/usr/bin/nghttp $(BUILD_DIST)/nghttp2-client/usr/bin
	cp -a $(BUILD_STAGE)/nghttp2/usr/share/man/man1/nghttp.1 $(BUILD_DIST)/nghttp2-client/usr/share/man/man1

	#nghttp2.mk Sign
	$(call SIGN,libnghttp2-14,general.xml)
	$(call SIGN,nghttp2-proxy,general.xml)
	$(call SIGN,nghttp2-server,general.xml)
	$(call SIGN,nghttp2-client,general.xml)
	
	# nghttp2.mk Make .debs
	$(call PACK,libnghttp2-14,DEB_NGHTTP2_V)
	$(call PACK,libnghttp2-dev,DEB_NGHTTP2_V)
	$(call PACK,nghttp2-proxy,DEB_NGHTTP2_V)
	$(call PACK,nghttp2-server,DEB_NGHTTP2_V)
	$(call PACK,nghttp2-client,DEB_NGHTTP2_V)
	
	# nghttp2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnghttp2-{14,dev} $(BUILD_DIST)/nghttp2-{client,proxy,server}

.PHONY: nghttp2 nghttp2-package
