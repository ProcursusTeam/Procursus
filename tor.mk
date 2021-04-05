ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += tor
TOR_VERSION  := 0.4.5.6
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
		--build=$$($(BUILD_MISC)/config.guess) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--host=$(GNU_HOST_TRIPLE) \
		--disable-tool-name-check \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var \
		--enable-zstd \
		--disable-html-manual \
		--enable-lzma \
		--disable-seccomp \
		--disable-unittests
	+$(MAKE) -C $(BUILD_WORK)/tor \
		CC=$(CC) \
		CPP="$(CXX)" \
		CFLAGS="$(CFLAGS)" \
		LFLAGS2="$(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/tor install \
		DESTDIR="$(BUILD_STAGE)/tor"
	mkdir -p $(BUILD_STAGE)/tor/{Library/LaunchDaemons,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec}
	cp -a $(BUILD_INFO)/org.torproject.tor.plist $(BUILD_STAGE)/tor/Library/LaunchDaemons
	cp -a $(BUILD_INFO)/tor-wrapper $(BUILD_STAGE)/tor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	touch $(BUILD_WORK)/tor/.build_complete
endif

tor-package: tor-stage
	# tor.mk Package Structure
	rm -rf $(BUILD_DIST)/tor

	# tor.mk Prep tor
	cp -a $(BUILD_STAGE)/tor $(BUILD_DIST)

	# tor.mk Sign
	$(call SIGN,tor,general.xml)

	# tor.mk Make .debs
	$(call PACK,tor,DEB_TOR_V)

	# tor.mk Build cleanup
	rm -rf $(BUILD_DIST)/tor

.PHONY: tor tor-package
