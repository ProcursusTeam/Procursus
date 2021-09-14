ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += shared-mime-info
SHARED-MINE-INFO_VERSION := 2.1
DEB_SHARED-MINE-INFO_V   ?= $(SHARED-MINE-INFO_VERSION)

shared-mime-info-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/$(SHARED-MINE-INFO_VERSION)/shared-mime-info-$(SHARED-MINE-INFO_VERSION).tar.gz
	$(call EXTRACT_TAR,shared-mime-info-$(SHARED-MINE-INFO_VERSION).tar.gz,shared-mime-info-$(SHARED-MINE-INFO_VERSION),shared-mime-info)
	mkdir -p $(BUILD_WORK)/shared-mime-info/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/shared-mime-info/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/shared-mime-info/.build_complete),)
shared-mime-info:
	@echo "Using previously built shared-mime-info."
else
shared-mime-info: shared-mime-info-setup glib2.0
	cd $(BUILD_WORK)/shared-mime-info/build && meson \
		--cross-file cross.txt \
		..
	sed -i 's/xmlto -o/xmlto --skip-validation -o/g' $(BUILD_WORK)/shared-mime-info/build/build.ninja
	+ninja -C $(BUILD_WORK)/shared-mime-info/build
	+DESTDIR="$(BUILD_STAGE)/shared-mime-info" ninja -C $(BUILD_WORK)/shared-mime-info/build install
	+DESTDIR="$(BUILD_BASE)" ninja -C $(BUILD_WORK)/shared-mime-info/build install
	$(call AFTER_BUILD)
endif

shared-mime-info-package: shared-mime-info-stage
# shared-mime-info.mk Package Structure
	rm -rf $(BUILD_DIST)/shared-mime-info
	
# shared-mime-info.mk Prep shared-mime-info
	cp -a $(BUILD_STAGE)/shared-mime-info $(BUILD_DIST)
	
# shared-mime-info.mk Sign
	$(call SIGN,shared-mime-info,general.xml)
	
# shared-mime-info.mk Make .debs
	$(call PACK,shared-mime-info,DEB_SHARED-MINE-INFO_V)
	
# shared-mime-info.mk Build cleanup
	rm -rf $(BUILD_DIST)/shared-mime-info

.PHONY: shared-mime-info shared-mime-info-package