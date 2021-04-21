ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libev
LIBEV_VERSION := 4.33
DEB_LIBEV_V   ?= $(LIBEV_VERSION)

libev-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://dist.schmorp.de/libev/libev-$(LIBEV_VERSION).tar.gz
	$(call EXTRACT_TAR,libev-$(LIBEV_VERSION).tar.gz,libev-$(LIBEV_VERSION),libev)

ifneq ($(wildcard $(BUILD_WORK)/libev/.build_complete),)
libev:
	@echo "Using previously built libev."
else
libev: libev-setup
	cd $(BUILD_WORK)/libev && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libev install \
		DESTDIR=$(BUILD_STAGE)/libev
	# Do not make install to build_base do to conflicts with event.h from libevent.
	cp -a $(BUILD_STAGE)/libev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ev{,++}.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/libev/.build_complete
endif

libev-package: libev-stage
	# libev.mk Package Structure
	rm -rf $(BUILD_DIST)/libev{4,{,-libevent}-dev}
	mkdir -p $(BUILD_DIST)/libev4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libev-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} \
		$(BUILD_DIST)/libev-libevent-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libev.mk Prep libev4
	cp -a $(BUILD_STAGE)/libev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libev.4.dylib $(BUILD_DIST)/libev4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libev.mk Prep libev-dev
	cp -a $(BUILD_STAGE)/libev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/!(event.h) $(BUILD_DIST)/libev-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libev.4.dylib) $(BUILD_DIST)/libev-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libev.mk Prep libev-libevent-dev
	cp -a $(BUILD_STAGE)/libev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/event.h $(BUILD_DIST)/libev-libevent-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libev.mk Sign
	$(call SIGN,libev4,general.xml)

	# libev.mk Make .debs
	$(call PACK,libev4,DEB_LIBEV_V)
	$(call PACK,libev-dev,DEB_LIBEV_V)
	$(call PACK,libev-libevent-dev,DEB_LIBEV_V)

	# libev.mk Build cleanup
	rm -rf $(BUILD_DIST)/libev{4,{,-libevent}-dev}

.PHONY: libev libev-package
