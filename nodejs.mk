ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += nodejs
NODEJS_VERSION := 14.13.1
DEB_NODEJS_V   ?= $(NODEJS_VERSION)

nodejs-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://nodejs.org/dist/v$(NODEJS_VERSION)/node-v$(NODEJS_VERSION).tar.gz
	$(call EXTRACT_TAR,node-v$(NODEJS_VERSION).tar.gz,node-v$(NODEJS_VERSION),nodejs)
	$(call DO_PATCH,nodejs,nodejs,-p1)
	$(SED) -i 's/@@IPHONEOSVERMIN@@/$(shell echo "$(PLATFORM_VERSION_MIN)" | cut -d= -f2)/g' $(BUILD_WORK)/nodejs/common.gypi

ifneq ($(UNAME),Darwin)
nodejs:
	@echo "nodejs building only supported on macOS"
else ifneq ($(wildcard $(BUILD_WORK)/nodejs/.build_complete),)
nodejs:
	@echo "Using previously built nodejs."
else
nodejs: nodejs-setup nghttp2 openssl brotli libc-ares libuv1
	cd $(BUILD_WORK)/nodejs && GYP_DEFINES="target_arch=arm64 host_os=mac target_os=ios" ./configure \
		--build=$$($(BUILD_MISC)/config.guess) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--dest-os=ios \
		--dest-cpu=arm64 \
		--with-arm-fpu=neon \
		--cross-compiling \
		--without-npm \
		--shared \
		--shared-openssl \
		--shared-zlib \
		--shared-libuv \
		--shared-brotli \
		--shared-brotli-libpath=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
		--shared-nghttp2 \
		--shared-cares \
		--experimental-http-parser \
		--openssl-use-def-ca-store \
		--with-intl=full-icu --download=all

	+$(MAKE) -C $(BUILD_WORK)/nodejs \
		GYP_DEFINES="target_arch=arm64 host_os=mac target_os=ios"

	+$(MAKE) -C $(BUILD_WORK)/nodejs install \
		DESTDIR=$(BUILD_STAGE)/nodejs

	mkdir -p $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	cp -a $(BUILD_WORK)/nodejs/out/Release/node $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	touch $(BUILD_WORK)/nodejs/.build_complete
endif

nodejs-package: nodejs-stage
	# nodejs.mk Package Structure
	rm -rf \
		$(BUILD_DIST)/libnode{83,-dev} \
		$(BUILD_DIST)/nodejs
	mkdir -p \
		$(BUILD_DIST)/libnode-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		$(BUILD_DIST)/libnode83/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share \
		$(BUILD_DIST)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/doc/nodejs

	# nodejs.mk Prep libnode-dev
	cp -a $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/libnode-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)

	# nodejs.mk Prep libnode83
	cp -a $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib $(BUILD_DIST)/libnode83/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/systemtap $(BUILD_DIST)/libnode83/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share

	# nodejs.mk Prep nodejs
	cp -a $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin $(BUILD_DIST)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/doc/node/* $(BUILD_DIST)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/doc/nodejs
	cp -a $(BUILD_STAGE)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man $(BUILD_DIST)/nodejs/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share

	# nodejs.mk Sign
	$(call SIGN,libnode83,general.xml)
	$(call SIGN,nodejs,general.xml)

	# nodejs.mk Make .debs
	$(call PACK,libnode-dev,DEB_NODEJS_V)
	$(call PACK,libnode83,DEB_NODEJS_V)
	$(call PACK,nodejs,DEB_NODEJS_V)

	# nodejs.mk Build cleanup
	rm -rf \
		$(BUILD_DIST)/libnode{83,-dev} \
		$(BUILD_DIST)/nodejs

.PHONY: nodejs nodejs-package
