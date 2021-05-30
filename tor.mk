ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += tor
TOR_VERSION  := 0.4.5.8
DEB_TOR_V    ?= $(TOR_VERSION)

tor-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dist.torproject.org/tor-$(TOR_VERSION).tar.gz{,.asc}
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
		--disable-unittests
	+$(MAKE) -C $(BUILD_WORK)/tor \
		CC=$(CC) \
		CPP="$(CXX)" \
		CFLAGS="$(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/tor install \
		DESTDIR="$(BUILD_STAGE)/tor"
	mkdir -p $(BUILD_STAGE)/tor/$(MEMO_PREFIX){/Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/libexec}
	cp -a $(BUILD_MISC)/tor/org.torproject.tor.plist $(BUILD_STAGE)/tor/$(MEMO_PREFIX)/Library/LaunchDaemons
	$(SED) -i -e 's/@MEMO_PREFIX@/$(MEMO_PREFIX)/g' -e 's/@MEMO_SUB_PREFIX@/$(MEMO_SUB_PREFIX)/g' \
		$(BUILD_STAGE)/tor/$(MEMO_PREFIX)/Library/LaunchDaemons/org.torproject.tor.plist
	cp -a $(BUILD_MISC)/tor/tor-wrapper $(BUILD_STAGE)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	$(SED) -i -e 's/@MEMO_PREFIX@/$(MEMO_PREFIX)/g' -e 's/@MEMO_SUB_PREFIX@/$(MEMO_SUB_PREFIX)/g' \
		$(BUILD_STAGE)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/tor-wrapper
	touch $(BUILD_WORK)/tor/.build_complete
endif

tor-package: tor-stage
	# tor.mk Package Structure
	rm -rf $(BUILD_DIST)/tor{,-geoipdb}
	mkdir -p $(BUILD_DIST)/tor-geoipdb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	
	# tor.mk Prep tor
	cp -a $(BUILD_STAGE)/tor $(BUILD_DIST)
	rm -rf $(BUILD_DIST)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tor
	
	# tor.mk Prep tor
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
