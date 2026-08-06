ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += shared-mime-info
SHARED_MIME_INFO_VERSION := 2.2
DEB_SHARED_MIME_INFO_V   ?= $(SHARED_MIME_INFO_VERSION)

shared-mime-info-setup: setup
	wget -q -nc -O$(BUILD_SOURCE)/shared-mime-info-$(SHARED_MIME_INFO_VERSION).tar.bz2 https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/$(SHARED_MIME_INFO_VERSION)/shared-mime-info-$(SHARED_MIME_INFO_VERSION).tar.bz2
	$(call EXTRACT_TAR,shared-mime-info-$(SHARED_MIME_INFO_VERSION).tar.bz2,shared-mime-info-$(SHARED_MIME_INFO_VERSION),shared-mime-info)
	$(call DO_PATCH,shared-mime-info,shared-mime-info,-p1)
	mkdir -p $(BUILD_WORK)/shared-mime-info/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/shared-mime-info/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/shared-mime-info/.build_complete),)
shared-mime-info:
	@echo "Using previously built shared-mime-info."
else
# xmlto required at build time
shared-mime-info: shared-mime-info-setup gettext glib2.0
	cd $(BUILD_WORK)/shared-mime-info/build && meson \
		--cross-file cross.txt \
		--buildtype=release \
		..
	+ninja -C $(BUILD_WORK)/shared-mime-info/build
	+ninja -C $(BUILD_WORK)/shared-mime-info/build install \
		DESTDIR="$(BUILD_STAGE)/shared-mime-info"
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
	$(call PACK,shared-mime-info,DEB_SHARED_MIME_INFO_V)

	# shared-mime-info.mk Build cleanup
	rm -rf $(BUILD_DIST)/shared-mime-info

.PHONY: shared-mime-info shared-mime-info-package
