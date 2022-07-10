ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += tor
TOR_VERSION  := 0.4.6.8
DEB_TOR_V    ?= $(TOR_VERSION)

tor-setup: setup
	wget2 -q -nc -P $(BUILD_SOURCE) https://dist.torproject.org/tor-$(TOR_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,tor-$(TOR_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,tor-$(TOR_VERSION).tar.gz,tor-$(TOR_VERSION),tor)

ifneq ($(wildcard $(BUILD_WORK)/tor/.build_complete),)
tor:
	@echo "Using previously built tor."
else
tor: tor-setup libevent openssl xz zstd libscrypt
	cd $(BUILD_WORK)/tor && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-tool-name-check \
		--enable-zstd \
		--disable-html-manual \
		--enable-lzma \
		--disable-seccomp \
		--disable-unittests \
		LZMA_LIBS='$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/liblzma.dylib'
	# While _NSGetEnviron exists, it doesn't have a prototype in iOS 12 SDKs
	sed -i '/HAVE__NSGETENVIRON/d' $(BUILD_WORK)/tor/orconfig.h
	+$(MAKE) -C $(BUILD_WORK)/tor \
		CC="$(CC)" \
		CPP="$(CXX)" \
		CFLAGS="$(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/tor install \
		DESTDIR="$(BUILD_STAGE)/tor"

	mkdir -p $(BUILD_STAGE)/tor/$(MEMO_PREFIX){/Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/libexec}
	install -m644 $(BUILD_MISC)/tor/org.torproject.tor.plist $(BUILD_STAGE)/tor/$(MEMO_PREFIX)/Library/LaunchDaemons
	sed -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/tor/$(MEMO_PREFIX)/Library/LaunchDaemons/org.torproject.tor.plist
	install -m755 $(BUILD_MISC)/tor/tor-wrapper $(BUILD_STAGE)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	sed -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/tor-wrapper
	$(call AFTER_BUILD)
endif

tor-package: tor-stage
	# tor.mk Package Structure
	rm -rf $(BUILD_DIST)/tor{,-geoipdb}
	mkdir -p $(BUILD_DIST)/tor-geoipdb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# tor.mk Prep tor
	cp -a $(BUILD_STAGE)/tor $(BUILD_DIST)
	rm -rf $(BUILD_DIST)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tor

	# tor.mk Prep tor-geoipdb
	cp -a $(BUILD_STAGE)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tor \
		$(BUILD_DIST)/tor-geoipdb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# tor.mk Sign
	$(call SIGN,tor,general.xml)

	# tor.mk Make .debs
	$(call PACK,tor,DEB_TOR_V)
	$(call PACK,tor-geoipdb,DEB_TOR_V)

	# tor.mk Build cleanup
	rm -rf $(BUILD_DIST)/tor{,-geoipdb}

.PHONY: tor tor-package
