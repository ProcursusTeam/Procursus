ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += at-spi2-atk
AT-SPI2-ATK_VERSION := 2.38.0
DEB_AT-SPI2-ATK_V   ?= $(AT-SPI2-ATK_VERSION)

at-spi2-atk-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download-fallback.gnome.org/sources/at-spi2-atk/$(shell echo $(AT-SPI2-ATK_VERSION) | cut -f-2 -d.)/at-spi2-atk-$(AT-SPI2-ATK_VERSION).tar.xz
	$(call EXTRACT_TAR,at-spi2-atk-$(AT-SPI2-ATK_VERSION).tar.xz,at-spi2-atk-$(AT-SPI2-ATK_VERSION),at-spi2-atk)
	mkdir -p $(BUILD_WORK)/at-spi2-atk/build
	echo -e "[host_machine]\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	system = 'darwin'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	needs_exe_wrapper = true\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	objc = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/at-spi2-atk/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/at-spi2-atk/.build_complete),)
at-spi2-atk:
	@echo "Using previously built at-spi2-atk."
else
at-spi2-atk: at-spi2-atk-setup atk at-spi2-atk dbus glib2.0
	cd $(BUILD_WORK)/at-spi2-atk/build && meson \
	--cross-file cross.txt \
	-Dintrospection=false \
	..
	ninja -C $(BUILD_WORK)/at-spi2-atk/build
	+DESTDIR="$(BUILD_STAGE)/at-spi2-atk" ninja -C $(BUILD_WORK)/at-spi2-atk/build install
	$(call AFTER_BUILD,copy)
endif

at-spi2-atk-package: at-spi2-atk-stage
	# at-spi2-atk.mk Package Structure
	rm -rf $(BUILD_DIST)/libatk-adaptor $(BUILD_DIST)/libatk-bridge2.0-{0,dev}
	mkdir -p $(BUILD_DIST)/libatk-adaptor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libatk-bridge2.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libatk-bridge2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include}

	# at-spi2-atk.mk libatk-adaptor
	cp -a $(BUILD_STAGE)/at-spi2-atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{gnome-settings-daemon-3.0,gtk-2.0} \
		$(BUILD_DIST)/libatk-adaptor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# at-spi2-atk.mk Prep libatk-bridge2.0-0
	cp -a $(BUILD_STAGE)/at-spi2-atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libatk-bridge-2.0.0.dylib \
		$(BUILD_DIST)/libatk-bridge2.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# at-spi2-atk.mk Prep libatk-bridge2.0-dev
	cp -a $(BUILD_STAGE)/at-spi2-atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libatk-bridge-2.0.0.dylib|gnome-settings-daemon-3.0|gtk-2.0) \
		$(BUILD_DIST)/libatk-bridge2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/at-spi2-atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/at-spi2-atk \
		$(BUILD_DIST)/libatk-bridge2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include


	# at-spi2-atk.mk Sign
	$(call SIGN,libatk-adaptor,general.xml)
	$(call SIGN,libatk-bridge2.0-0,general.xml)

	# at-spi2-atk.mk Make .debs
	$(call PACK,libatk-adaptor,DEB_AT-SPI2-ATK_V)
	$(call PACK,libatk-bridge2.0-0,DEB_AT-SPI2-ATK_V)
	$(call PACK,libatk-bridge2.0-dev,DEB_AT-SPI2-ATK_V)

	# at-spi2-atk.mk Build cleanup
	rm -rf $(BUILD_DIST)/libatk-adaptor $(BUILD_DIST)/libatk-bridge2.0-{0,dev}

.PHONY: at-spi2-atk at-spi2-atk-package


