ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libepoxy
LIBEPOXY_VERSION := 1.5.5
DEB_LIBEPOXY_V   ?= $(LIBEPOXY_VERSION)

libepoxy-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/libepoxy/$(shell echo $(LIBEPOXY_VERSION) | cut -d. -f-2)/libepoxy-$(LIBEPOXY_VERSION).tar.xz
	$(call EXTRACT_TAR,libepoxy-$(LIBEPOXY_VERSION).tar.xz,libepoxy-$(LIBEPOXY_VERSION),libepoxy)
	mkdir -p $(BUILD_WORK)/libepoxy/build
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
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/libepoxy/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/libepoxy/.build_complete),)
libepoxy:
	@echo "Using previously built libepoxy."
else
libepoxy: libepoxy-setup libx11 mesa
	cd $(BUILD_WORK)/libepoxy/build && PKG_CONFIG="pkg-config" meson \
		--cross-file cross.txt \
		-Dtests=false \
		..
	+ninja -C $(BUILD_WORK)/libepoxy/build
	+DESTDIR="$(BUILD_STAGE)/libepoxy" ninja -C $(BUILD_WORK)/libepoxy/build install
	+DESTDIR="$(BUILD_BASE)" ninja -C $(BUILD_WORK)/libepoxy/build install
	touch $(BUILD_WORK)/libepoxy/.build_complete
endif

libepoxy-package: libepoxy-stage
	# libepoxy.mk Package Structure
	rm -rf $(BUILD_DIST)/libepoxy
	mkdir -p $(BUILD_DIST)/libepoxy
	
	# libepoxy.mk Prep libepoxy
	cp -a $(BUILD_STAGE)/libepoxy $(BUILD_DIST)
	
	# libepoxy.mk Sign
	$(call SIGN,libepoxy,general.xml)
	
	# libepoxy.mk Make .debs
	$(call PACK,libepoxy,DEB_LIBEPOXY_V)
	
	# libepoxy.mk Build cleanup
	rm -rf $(BUILD_DIST)/libepoxy

.PHONY: libepoxy libepoxy-package

