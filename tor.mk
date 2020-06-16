ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += tor
DOWNLOAD     += https://dist.torproject.org/tor-$(TOR_VERSION).tar.gz
TOR_VERSION  := 0.4.3.5
DEB_TOR_V    ?= $(TOR_VERSION)

tor-setup: setup
	$(call EXTRACT_TAR,tor-$(TOR_VERSION).tar.gz,tor-$(TOR_VERSION),tor)

ifneq ($(wildcard $(BUILD_WORK)/tor/.build_complete),)
tor:
	@echo "Using previously built tor."
else
tor: tor-setup
	cd $(BUILD_WORK)/tor && ./configure --prefix=$(BUILD_STAGE)/tor \
		--host=$(GNU_HOST_TRIPLE) \
		--disable-tool-name-check
	+$(MAKE) -C $(BUILD_WORK)/tor \
		CC=$(CC) \
		CPP="$(CXX)" \
		CFLAGS="$(CFLAGS)" \
		LFLAGS2="$(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/tor install
	touch $(BUILD_WORK)/tor/.build_complete
endif

tor-package: tor-stage
	# tor.mk Package Structure
	rm -rf $(BUILD_DIST)/tor
	mkdir -p $(BUILD_DIST)/tor
	mkdir -p $(BUILD_DIST)/tor/usr
	
	# tor.mk Prep tor
	cp -a $(BUILD_STAGE)/tor/etc $(BUILD_DIST)/tor
	cp -a $(BUILD_STAGE)/tor/bin $(BUILD_DIST)/tor
	cp -a $(BUILD_STAGE)/tor/share $(BUILD_DIST)/tor/usr/
	
	# tor.mk Sign
	$(call SIGN,tor,general.xml)
	
	# tor.mk Make .debs
	$(call PACK,tor,DEB_TOR_V)
	
	# tor.mk Build cleanup
	rm -rf $(BUILD_DIST)/tor

.PHONY: tor tor-package
