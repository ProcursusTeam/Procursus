ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += libwebsockets
LIBWEBSOCKETS_VERSION := 4.3.1
DEB_LIBWEBSOCKETS_V   ?= $(LIBWEBSOCKETS_VERSION)

libwebsockets-setup: setup
	$(call GITHUB_ARCHIVE,warmcat,libwebsockets,$(LIBWEBSOCKETS_VERSION),v$(LIBWEBSOCKETS_VERSION))
	$(call EXTRACT_TAR,libwebsockets-$(LIBWEBSOCKETS_VERSION).tar.gz,libwebsockets-$(LIBWEBSOCKETS_VERSION),libwebsockets)
	mkdir -p $(BUILD_WORK)/libwebsockets/build

ifneq ($(wildcard $(BUILD_WORK)/libwebsockets/.build_complete),)
libwebsockets:
	@echo "Using previously built libwebsockets."
else
libwebsockets: libwebsockets-setup openssl brotli glib2.0 libuv1 libev
	cd $(BUILD_WORK)/libwebsockets/build && cmake .. \
		$(DEFAULT_CMAKE_FLAGS) \
		-DLWS_WITH_HTTP2=1 \
		-DLWS_WITH_DISTRO_RECOMMENDED=1 \
		-DDISABLE_WERROR=1 \
		-DLWS_WITH_LWSWS=1 \
		-DLWS_ROLE_MQTT=1 \
		-DLWS_IPV6=1 \
		-DLWS_WITH_HTTP_PROXY=1 \
		-DLWS_WITH_ZIP_FOPS=1 \
		-DLWS_WITH_SOCKS5=1 \
		-DLWS_WITH_ACCESS_LOG=1 \
		-DLWS_WITH_HTTP_STREAM_COMPRESSION=1 \
		-DLWS_WITH_HTTP_BROTLI=1 \
		-DLWS_WITH_RANGES=1 \
		-DLWS_WITH_THREADPOOL=1 \
		-DLWS_WITH_ACME=1 \
		-DLWS_WITH_FTS=1 \
		-DLWS_WITH_SYS_FAULT_INJECTION=1 \
		-DLWS_WITH_SYS_METRICS=1 \
		-DOPENSSL_EXECUTABLE=$(command -v openssl)
	+$(MAKE) -C $(BUILD_WORK)/libwebsockets/build
	+$(MAKE) -C $(BUILD_WORK)/libwebsockets/build install \
		DESTDIR="$(BUILD_STAGE)/libwebsockets"
	$(call AFTER_BUILD,copy)
endif

libwebsockets-package: libwebsockets-stage
	# libwebsockets.mk Package Structure
	rm -rf $(BUILD_DIST)/{lwsws,libwebsockets{19,-{,dev,evlib-{ev,uv,glib,event},test-server{,-common}}}}
	mkdir -p $(BUILD_DIST)/libwebsockets{19,-{,dev,evlib-{ev,uv,glib,event},test-server{,-common}}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libwebsockets{19,-{,dev,evlib-{ev,uv,glib,event}}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/{lwsws,libwebsockets-test-server}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/libwebsockets-test-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/lwsws/$(MEMO_PREFIX)/{var/www/lwsws-default,etc/lwsws/conf.d,Library/LaunchDaemons}

	# libwebsockets.mk Prep libwebsockets-evlib-{ev,uv,glib,event}
	for evlib in ev uv glib event; do \
		cp -a $(BUILD_STAGE)/libwebsockets/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwebsockets-evlib_$${evlib}.dylib $(BUILD_DIST)/libwebsockets-evlib-$${evlib}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib; \
	done

	# libwebsockets.mk Prep libwebsockets19
	cp -a $(BUILD_STAGE)/libwebsockets/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwebsockets.19.dylib $(BUILD_DIST)/libwebsockets19/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib;

	# libwebsockets.mk Prep libwebsockets-dev
	cp -a $(BUILD_STAGE)/libwebsockets/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,cmake,libwebsockets.{dylib,a}} $(BUILD_DIST)/libwebsockets-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib;
	cp -a $(BUILD_STAGE)/libwebsockets/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libwebsockets-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX);

	# libwebsockets.mk Prep lwsws
	cp -a $(BUILD_STAGE)/libwebsockets/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lwsws $(BUILD_DIST)/lwsws/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
	cp -a $(BUILD_MISC)/lwsws/conf $(BUILD_DIST)/lwsws/$(MEMO_PREFIX)/etc/lwsws/conf
	sed 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $(BUILD_MISC)/lwsws/example.conf > $(BUILD_DIST)/lwsws/$(MEMO_PREFIX)/etc/lwsws/conf.d/example.conf
	sed 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $(BUILD_MISC)/lwsws/index.html > $(BUILD_DIST)/lwsws/$(MEMO_PREFIX)/var/www/lwsws-default/index.html
	sed 's|@MEMO_PREFIX@@MEMO_SUB_PREFIX@|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/lwsws/org.libwebsockets.lwsws.plist > $(BUILD_DIST)/lwsws/$(MEMO_PREFIX)/Library/LaunchDaemons/org.libwebsockets.lwsws.plist

	# libwebsockets.mk Prep libwebsockets-test-server-common
	cp -a $(BUILD_STAGE)/libwebsockets/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libwebsockets-test-server-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX);

	# libwebsockets.mk Prep libwebsockets-test-server
	cp -a $(BUILD_STAGE)/libwebsockets/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/libwebsockets-test-* $(BUILD_DIST)/libwebsockets-test-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;

	# libwebsockets.mk Sign
	$(call SIGN,libwebsockets19,general.xml)
	$(call SIGN,libwebsockets-evlib-uv,general.xml)
	$(call SIGN,libwebsockets-evlib-ev,general.xml)
	$(call SIGN,libwebsockets-evlib-glib,general.xml)
	$(call SIGN,libwebsockets-evlib-event,general.xml)
	$(call SIGN,libwebsockets-test-server,general.xml)
	$(call SIGN,lwsws,general.xml)

	# libwebsockets.mk Make .debs
	$(call PACK,libwebsockets19,DEB_LIBWEBSOCKETS_V)
	$(call PACK,libwebsockets-evlib-ev,DEB_LIBWEBSOCKETS_V)
	$(call PACK,libwebsockets-evlib-uv,DEB_LIBWEBSOCKETS_V)
	$(call PACK,libwebsockets-evlib-glib,DEB_LIBWEBSOCKETS_V)
	$(call PACK,libwebsockets-evlib-event,DEB_LIBWEBSOCKETS_V)
	$(call PACK,libwebsockets-dev,DEB_LIBWEBSOCKETS_V)
	$(call PACK,libwebsockets-test-server,DEB_LIBWEBSOCKETS_V)
	$(call PACK,libwebsockets-test-server-common,DEB_LIBWEBSOCKETS_V)
	$(call PACK,lwsws,DEB_LIBWEBSOCKETS_V)

	# libwebsockets.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lwsws,libwebsockets{19,-{,dev,evlib-{ev,uv,glib,event},test-server{,-common}}}}

.PHONY: libwebsockets libwebsockets-package

