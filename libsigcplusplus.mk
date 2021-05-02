ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += libsigcplusplus
LIBSIGCPLUSPLUS_VERSION := 2.10.3
DEB_LIBSIGCPLUSPLUS_V   ?= $(LIBSIGCPLUSPLUS_VERSION)

libsigcplusplus-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.gnome.org/sources/libsigc++/2.10/libsigc++-$(LIBSIGCPLUSPLUS_VERSION).tar.xz
	$(call EXTRACT_TAR,libsigc++-$(LIBSIGCPLUSPLUS_VERSION).tar.xz,libsigc++-$(LIBSIGCPLUSPLUS_VERSION),libsigcplusplus)

ifneq ($(wildcard $(BUILD_WORK)/libsigcplusplus/.build_complete),)
libsigcplusplus:
	@echo "Using previously built libsigcplusplus."
else
libsigcplusplus: libsigcplusplus-setup
	cd $(BUILD_WORK)/libsigcplusplus && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--enable-shared
	+$(MAKE) -C $(BUILD_WORK)/libsigcplusplus
	+$(MAKE) -C $(BUILD_WORK)/libsigcplusplus install \
		DESTDIR=$(BUILD_STAGE)/libsigcplusplus
	+$(MAKE) -C $(BUILD_WORK)/libsigcplusplus install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libsigcplusplus/.build_complete
endif

libsigcplusplus-package: libsigcplusplus-stage
	# libsigcplusplus.mk Package Structure
	rm -rf $(BUILD_DIST)/libsigc++-2.0-{0v5,dev}
	mkdir -p $(BUILD_DIST)/libsigc++-2.0-{0v5,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsigcplusplus.mk Prep libsigc++-2.0-0v5
	cp -a $(BUILD_STAGE)/libsigcplusplus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsigc-2.0.0.dylib $(BUILD_DIST)/libsigc++-2.0-0v5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsigcplusplus.mk Prep libsigc++-2.0-dev
	cp -a $(BUILD_STAGE)/libsigcplusplus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsigc++-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libsigcplusplus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libsigc-2.0.0.dylib) $(BUILD_DIST)/libsigc++-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsigcplusplus.mk Sign
	$(call SIGN,libsigc++-2.0-0v5,general.xml)

	# libsigcplusplus.mk Make .debs
	$(call PACK,libsigc++-2.0-0v5,DEB_LIBSIGCPLUSPLUS_V)
	$(call PACK,libsigc++-2.0-dev,DEB_LIBSIGCPLUSPLUS_V)

	# libsigcplusplus.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsigc++-2.0-{0v5,dev}

.PHONY: libsigcplusplus libsigcplusplus-package
