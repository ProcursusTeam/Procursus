ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += tor
TOR_VERSION  := 0.4.3.5
DEB_TOR_V    ?= $(TOR_VERSION)-1

tor-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dist.torproject.org/tor-$(TOR_VERSION).tar.gz
	$(call EXTRACT_TAR,tor-$(TOR_VERSION).tar.gz,tor-$(TOR_VERSION),tor)

ifneq ($(wildcard $(BUILD_WORK)/tor/.build_complete),)
tor:
	@echo "Using previously built tor."
else
tor: tor-setup libevent openssl xz zstd
	cd $(BUILD_WORK)/tor && ./configure \
		--prefix=/usr \
		--host=$(GNU_HOST_TRIPLE) \
		--disable-tool-name-check \
		--sysconfdir=/etc \
		--enable-zstd \
		--disable-html-manual \
		--enable-lzma
	+$(MAKE) -C $(BUILD_WORK)/tor \
		CC=$(CC) \
		CPP="$(CXX)" \
		CFLAGS="$(CFLAGS)" \
		LFLAGS2="$(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/tor install \
		DESTDIR="$(BUILD_STAGE)/tor"
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
