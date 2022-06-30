ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxcvt
LIBXCVT_VERSION := 0.1.1
DEB_LIBXCVT_V   ?= $(LIBXCVT_VERSION)

libxcvt-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libxcvt-$(LIBXCVT_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,libxcvt-$(LIBXCVT_VERSION).tar.xz)
	$(call EXTRACT_TAR,libxcvt-$(LIBXCVT_VERSION).tar.xz,libxcvt-$(LIBXCVT_VERSION),libxcvt)
	mkdir -p $(BUILD_WORK)/libxcvt/build
	echo -e "[host_machine]\n \
	system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/libxcvt/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/libxcvt/.build_complete),)
libxcvt:
	@echo "Using previously built libxcvt."
else
libxcvt: libxcvt-setup
	cd $(BUILD_WORK)/libxcvt/build && meson --cross-file cross.txt ..
	+DESTDIR=$(BUILD_STAGE)/libxcvt ninja -C $(BUILD_WORK)/libxcvt/build install
	$(call AFTER_BUILD,copy)
endif

libxcvt-package: libxcvt-stage
	# libxcvt.mk Package Structure
	rm -rf $(BUILD_DIST)/{libxcvt{0,-dev},xcvt}
	mkdir -p $(BUILD_DIST)/xcvt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libxcvt{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcvt.mk Prep libxcvt0
	cp -a $(BUILD_STAGE)/libxcvt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxcvt.0.dylib $(BUILD_DIST)/libxcvt0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcvt.mk Prep libxcvt-dev
	cp -a $(BUILD_STAGE)/libxcvt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxcvt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxcvt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libxcvt.dylib} $(BUILD_DIST)/libxcvt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcvt.mk Prep xcvt
	cp -a $(BUILD_STAGE)/libxcvt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/xcvt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxcvt.mk Sign
	$(call SIGN,libxcvt0,general.xml)
	$(call SIGN,xcvt,general.xml)

	# libxcvt.mk Make .debs
	$(call PACK,libxcvt0,DEB_LIBXCVT_V)
	$(call PACK,libxcvt-dev,DEB_LIBXCVT_V)
	$(call PACK,xcvt,DEB_LIBXCVT_V)

	# libxcvt.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libxcvt{0,-dev},xcvt}

.PHONY: libxcvt libxcvt-package
