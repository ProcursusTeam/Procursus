ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libcdio
LIBCDIO_VERSION := 2.1.0
DEB_LIBCDIO_V   ?= $(LIBCDIO_VERSION)

libcdio-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://ftp.gnu.org/gnu/libcdio/libcdio-$(LIBCDIO_VERSION).tar.bz2
	$(call EXTRACT_TAR,libcdio-$(LIBCDIO_VERSION).tar.bz2,libcdio-$(LIBCDIO_VERSION),libcdio)

ifneq ($(wildcard $(BUILD_WORK)/libcdio/.build_complete),)
libcdio:
	@echo "Using previously built libcdio."
else
libcdio: libcdio-setup ncurses # libcddb
	cd $(BUILD_WORK)/libcdio && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-static \
		--enable-shared
	+$(MAKE) -C $(BUILD_WORK)/libcdio
	+$(MAKE) -C $(BUILD_WORK)/libcdio install \
		DESTDIR=$(BUILD_STAGE)/libcdio
	+$(MAKE) -C $(BUILD_WORK)/libcdio install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libcdio/.build_complete
endif

libcdio-package: libcdio-stage
	# libcdio.mk Package Structure
	rm -rf $(BUILD_DIST)/libcdio{19,-dev}
	mkdir -p $(BUILD_DIST)/libcdio{19,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include/cdio}
	
	# libcdio.mk Prep libcdio19
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcdio.19.dylib $(BUILD_DIST)/libcdio19/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcdio.mk Prep libcdio-dev
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio/{audio,bytesex,bytesex_asm,cd_types,cdio,cdio_config,cdtext,device,disc,ds,dvd,logging,memory,mmc,mmc_cmds,mmc,l_cmds,mmc_ll_cmds,mmc_util,posix,read,sector,track,types,utf8,util,version}.h $(BUILD_DIST)/libcdio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libcdio.{dylib,a}} $(BUILD_DIST)/libcdio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcdio.mk Prep libcdio++1
	
	# libcdio.mk Prep libcdio++-dev
	
	# libcdio.mk Prep libcdio-utils
	
	# libcdio.mk Prep libiso9660-11
	
	# libcdio.mk Prep libiso9660-dev
	
	# libcdio.mk Prep libiso9660++0
	
	# libcdio.mk Prep libiso9660++-dev
	
	# libcdio.mk Prep libudf0
	
	# libcdio.mk Prep libudf-dev
	
	# libcdio.mk Sign
	$(call SIGN,libcdio19,general.xml)
	
	# libcdio.mk Make .debs
	$(call PACK,libcdio19,DEB_LIBCDIO_V)
	$(call PACK,libcdio-dev,DEB_LIBCDIO_V)
	
	# libcdio.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcdio{19,-dev}

.PHONY: libcdio libcdio-package
