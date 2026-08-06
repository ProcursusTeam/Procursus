ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += wayland-protocols
WAYLAND_PROTOCOLS_VERSION := 1.25
DEB_WAYLAND_PROTOCOLS_V   ?= $(WAYLAND_PROTOCOLS_VERSION)

wayland-protocols-setup: setup
	wget -q -nc -O$(BUILD_SOURCE)/wayland-protocols-$(WAYLAND_PROTOCOLS_VERSION).tar.xz) https://wayland.freedesktop.org/releases/wayland-protocols-$(WAYLAND_PROTOCOLS_VERSION).tar.xz
	$(call EXTRACT_TAR,wayland-protocols-$(WAYLAND_PROTOCOLS_VERSION).tar.xz,wayland-protocols-$(WAYLAND_PROTOCOLS_VERSION),wayland-protocols)
	mkdir -p $(BUILD_WORK)/wayland-protocols/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/wayland-protocols/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/wayland-protocols/.build_complete),)
wayland-protocols:
	@echo "Using previously built wayland-protocols."
else
wayland-protocols: wayland-protocols-setup
	cd $(BUILD_WORK)/wayland-protocols/build && meson \
		--cross-file cross.txt \
		-Dtests=false \
		..
	+ninja -C $(BUILD_WORK)/wayland-protocols/build
	+ninja -C $(BUILD_WORK)/wayland-protocols/build install \
		DESTDIR="$(BUILD_STAGE)/wayland-protocols"
	$(call AFTER_BUILD)
endif

wayland-protocols-package: wayland-protocols-stage
	# wayland-protocols.mk Package Structure
	rm -rf $(BUILD_DIST)/wayland-protocols

	# wayland-protocols.mk Prep wayland-protocols
	cp -a $(BUILD_STAGE)/wayland-protocols $(BUILD_DIST)

	# wayland-protocols.mk Make .debs
	$(call PACK,wayland-protocols,DEB_WAYLAND_PROTOCOLS_V)

	# wayland-protocols.mk Build cleanup
	rm -rf $(BUILD_DIST)/wayland-protocols

.PHONY: wayland-protocols wayland-protocols-package
