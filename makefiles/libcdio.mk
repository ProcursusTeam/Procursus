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
libcdio: libcdio-setup ncurses libcddb
	cd $(BUILD_WORK)/libcdio && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libcdio
	+$(MAKE) -C $(BUILD_WORK)/libcdio install \
		DESTDIR=$(BUILD_STAGE)/libcdio
	+$(MAKE) -C $(BUILD_WORK)/libcdio install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libcdio/.build_complete
endif

libcdio-package: libcdio-stage
	# libcdio.mk Package Structure
	rm -rf $(BUILD_DIST)/libcdio{19,-dev,++1,++-dev,-utils}
	rm -rf $(BUILD_DIST)/libiso9660{-11,-dev,++0,++-dev}
	rm -rf $(BUILD_DIST)/libudf{0,-dev}
	mkdir -p $(BUILD_DIST)/lib{cdio{19,-dev,++1,++-dev},iso9660{-11,-dev,++0,++-dev},udf{0,-dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/lib{cdio,iso9660,udf}-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/cdio,lib/pkgconfig}
	mkdir -p $(BUILD_DIST)/lib{cdio,iso9660}++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/cdio++,lib/pkgconfig}
	mkdir -p $(BUILD_DIST)/libcdio-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libcdio.mk Prep libcdio19
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcdio.19.dylib $(BUILD_DIST)/libcdio19/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcdio.mk Prep libcdio-dev
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio/{audio,bytesex,bytesex_asm,cd_types,cdio,cdio_config,cdtext,device,disc,ds,dvd,logging,memory,mmc,mmc_cmds,mmc_hl_cmds,mmc_ll_cmds,mmc_util,posix,read,sector,track,types,utf8,util,version}.h $(BUILD_DIST)/libcdio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcdio.{dylib,a} $(BUILD_DIST)/libcdio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libcdio.pc $(BUILD_DIST)/libcdio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	
	# libcdio.mk Prep libcdio++1
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcdio++.1.dylib $(BUILD_DIST)/libcdio++1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libcdio.mk Prep libcdio++-dev
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio++/{cdio,cdtext,device,devices,disc,enum,mmc,read,track}.hpp $(BUILD_DIST)/libcdio++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcdio++.{a,dylib} $(BUILD_DIST)/libcdio++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libcdio++.pc $(BUILD_DIST)/libcdio++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	
	# libcdio.mk Prep libcdio-utils
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libcdio-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libcdio.mk Prep libiso9660-11
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiso9660.11.dylib $(BUILD_DIST)/libiso9660-11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcdio.mk Prep libiso9660-dev
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio/{iso9660,rock,xa}.h $(BUILD_DIST)/libiso9660-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiso9660.{a,dylib} $(BUILD_DIST)/libiso9660-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libiso9660.pc $(BUILD_DIST)/libiso9660-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	
	# libcdio.mk Prep libiso9660++0
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiso9660++.0.dylib $(BUILD_DIST)/libiso9660++0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcdio.mk Prep libiso9660++-dev
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio++/iso9660.hpp $(BUILD_DIST)/libiso9660++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiso9660++.{a,dylib} $(BUILD_DIST)/libiso9660++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libiso9660++.pc $(BUILD_DIST)/libiso9660++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	
	# libcdio.mk Prep libudf0
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libudf.0.dylib $(BUILD_DIST)/libudf0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcdio.mk Prep libudf-dev
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cdio/{ecma_167,udf{,_file,_time}}.h $(BUILD_DIST)/libudf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libudf.{a,dylib} $(BUILD_DIST)/libudf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcdio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libudf.pc $(BUILD_DIST)/libudf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	
	# libcdio.mk Sign
	$(call SIGN,libcdio19,general.xml)
	$(call SIGN,libcdio++1,general.xml)
	$(call SIGN,libiso9660-11,general.xml)
	$(call SIGN,libiso9660++0,general.xml)
	$(call SIGN,libudf0,general.xml)
	$(call SIGN,libcdio-utils,dd.xml)
	
	# libcdio.mk Make .debs
	$(call PACK,libcdio19,DEB_LIBCDIO_V)
	$(call PACK,libcdio-dev,DEB_LIBCDIO_V)
	$(call PACK,libcdio++1,DEB_LIBCDIO_V)
	$(call PACK,libcdio++-dev,DEB_LIBCDIO_V)
	$(call PACK,libcdio-utils,DEB_LIBCDIO_V)
	$(call PACK,libiso9660-11,DEB_LIBCDIO_V)
	$(call PACK,libiso9660-dev,DEB_LIBCDIO_V)
	$(call PACK,libiso9660++0,DEB_LIBCDIO_V)
	$(call PACK,libiso9660++-dev,DEB_LIBCDIO_V)
	$(call PACK,libudf0,DEB_LIBCDIO_V)
	$(call PACK,libudf-dev,DEB_LIBCDIO_V)
	
	# libcdio.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcdio{19,-dev,++1,++-dev,-utils}
	rm -rf  $(BUILD_DIST)/libiso9660{-11,-dev,++0,++-dev}
	rm -rf $(BUILD_DIST)/libudf{0,-dev}

.PHONY: libcdio libcdio-package
