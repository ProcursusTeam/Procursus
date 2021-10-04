ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += atk
ATK_VERSION := 2.36.0
DEB_ATK_V   ?= $(ATK_VERSION)

atk-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download-fallback.gnome.org/sources/atk/$(shell echo $(ATK_VERSION) | cut -f-2 -d.)/atk-$(ATK_VERSION).tar.xz
	$(call EXTRACT_TAR,atk-$(ATK_VERSION).tar.xz,atk-$(ATK_VERSION),atk)
	mkdir -p $(BUILD_WORK)/atk/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/atk/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/atk/.build_complete),)
atk:
	@echo "Using previously built atk."
else
atk: atk-setup glib2.0
	cd $(BUILD_WORK)/atk/build && meson \
	--cross-file cross.txt \
	-Dintrospection=false \
	..
	ninja -C $(BUILD_WORK)/atk/build
	+DESTDIR="$(BUILD_STAGE)/atk" ninja -C $(BUILD_WORK)/atk/build install
	$(call AFTER_BUILD,copy)
endif

atk-package: atk-stage
	# atk.mk Package Structure
	rm -rf $(BUILD_DIST)/libatk1.0-{0,data,dev}
	mkdir -p $(BUILD_DIST)/libatk1.0-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/libatk1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libatk1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include}
	
	# atk.mk Prep libatk1.0-data
	cp -a $(BUILD_STAGE)/atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale \
		$(BUILD_DIST)/libatk1.0-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# atk.mk Prep libatk1.0-0
	cp -a $(BUILD_STAGE)/atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libatk-1.0.0.dylib \
		$(BUILD_DIST)/libatk1.0-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# atk.mk Prep libatk1.0-dev
	cp -a $(BUILD_STAGE)/atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libatk-1.0.0.dylib) \
		$(BUILD_DIST)/libatk1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/atk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/atk-1.0 \
		$(BUILD_DIST)/libatk1.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	
	# atk.mk Sign
	$(call SIGN,libatk1.0-0,general.xml)
	
	# atk.mk Make .debs
	$(call PACK,libatk1.0-data,DEB_ATK_V)
	$(call PACK,libatk1.0-0,DEB_ATK_V)
	$(call PACK,libatk1.0-dev,DEB_ATK_V)
	
	# atk.mk Build cleanup
	rm -rf $(BUILD_DIST)/libatk1.0-{0,data,dev}

.PHONY: atk atk-package
