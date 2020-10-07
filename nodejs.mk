ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += nodejs
NODEJS_VERSION  := 14.13.0
DEB_NODEJS_V    ?= $(NODEJS_VERSION)


nodejs-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://nodejs.org/dist/v$(NODEJS_VERSION)/node-v$(NODEJS_VERSION).tar.gz
	$(call EXTRACT_TAR,node-v$(NODEJS_VERSION).tar.gz,node-v$(NODEJS_VERSION),nodejs)

ifneq ($(wildcard $(BUILD_WORK)/nodejs/.build_complete),)
nodejs:
	@echo "Using previously built nodejs."
else
nodejs: nodejs-setup nghttp2 openssl brotli libc-ares libuv1
	cd $(BUILD_WORK)/nodejs && GYP_DEFINES="target_arch=arm64 host_os=mac target_os=ios" ./configure \
		--prefix=/usr \
		--dest-cpu=arm64 \
		--cross-compiling \
		--dest-os=ios \
		--without-npm \
		--shared \
		--shared-openssl \
		--shared-zlib \
		--shared-brotli \
		--shared-libuv \
		--shared-brotli-libpath=$(BUILD_BASE)/usr/lib \
		--shared-cares \
		--shared-nghttp2 \
		--without-intl \
		--experimental-http-parser \
		--openssl-use-def-ca-store

	+$(MAKE) -C $(BUILD_WORK)/nodejs \
		GYP_DEFINES="target_arch=arm64 host_os=mac target_os=ios"

	+$(MAKE) -C $(BUILD_WORK)/nodejs install \
		DESTDIR=$(BUILD_STAGE)/nodejs
	
	mkdir -p $(BUILD_STAGE)/nodejs/usr/bin
	cp -a $(BUILD_WORK)/nodejs/out/Release/node $(BUILD_STAGE)/nodejs/usr/bin
	touch $(BUILD_WORK)/nodejs/.build_complete
endif

nodejs-package: nodejs-stage
	# nodejs.mk Package Structure
	rm -rf \
		$(BUILD_DIST)/libnode{83,-dev} \
		$(BUILD_DIST)/nodejs
	mkdir -p \
		$(BUILD_DIST)/libnode-dev/usr \
		$(BUILD_DIST)/libnode83/usr/lib \
		$(BUILD_DIST)/nodejs/usr/share/doc/node
	
	# nodejs.mk Prep libnode-dev
	cp -a $(BUILD_STAGE)/nodejs/usr/include $(BUILD_DIST)/libnode-dev/usr
	
	# nodejs.mk Prep libnode84
	cp -a $(BUILD_STAGE)/nodejs/usr/lib/libnode*.dylib $(BUILD_DIST)/libnode83/usr/lib
	
	# nodejs.mk Prep nodejs
	cp -a $(BUILD_STAGE)/nodejs/usr/bin $(BUILD_DIST)/libnode/usr
	
	# nodejs.mk Sign
	$(call SIGN,libnode83,general.xml)
	$(call SIGN,nodejs,general.xml)

	# nodejs.mk Make .debs
	$(call PACK,libenode-dev,DEB_NODEJS_V)
	$(call PACK,libenode83,DEB_NODEJS_V)
	$(call PACK,nodejs,DEB_NODEJS_V)

	# nodejs.mk Build cleanup
	rm -rf \
		$(BUILD_DIST)/libnode{83,-dev} \
		$(BUILD_DIST)/nodejs

.PHONY: nodejs nodejs-package
