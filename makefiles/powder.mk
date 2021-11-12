ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += powder
POWDER_VERSION := 96.2.350
DEB_POWDER_V   ?= $(POWDER_VERSION)

powder-setup: setup
	$(call GITHUB_ARCHIVE,The-Powder-Toy,The-Powder-Toy,$(POWDER_VERSION),v$(POWDER_VERSION))
	$(call EXTRACT_TAR,The-Powder-Toy-$(POWDER_VERSION).tar.gz,The-Powder-Toy-$(POWDER_VERSION),powder)
	sed -i -e '/pagezero_size/d' -e '/image_base/d' $(BUILD_WORK)/powder/meson.build
	sed -i -e '/ApplicationServices/d' $(BUILD_WORK)/powder/src/common/macosx.h
	mkdir -p $(BUILD_WORK)/powder/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/powder/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/powder/.build_complete),)
powder:
	@echo "Using previously built powder."
else
powder: powder-setup curl sdl2 fftw luajit
	cd $(BUILD_WORK)/powder/build && meson \
		-Dbuildtype=release \
		-Db_pie=false \
		-Db_staticpic=false \
		--cross-file cross.txt \
		..
	+ninja -C $(BUILD_WORK)/powder/build
	install -d $(BUILD_STAGE)/powder/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man6}
	install -m755 $(BUILD_WORK)/powder/build/powder $(BUILD_STAGE)/powder/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/powder
	install -m755 $(BUILD_WORK)/powder/resources/powder.man $(BUILD_STAGE)/powder/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man6/powder.6
	$(call AFTER_BUILD)
endif

powder-package: powder-stage
	# powder.mk Package Structure
	rm -rf $(BUILD_DIST)/powder

	# powder.mk Prep powder
	cp -a $(BUILD_STAGE)/powder $(BUILD_DIST)

	# powder.mk Sign
	$(call SIGN,powder,general.xml)

	# powder.mk Make .debs
	$(call PACK,powder,DEB_POWDER_V)

	# powder.mk Build cleanup
	rm -rf $(BUILD_DIST)/powder

.PHONY: powder powder-package
