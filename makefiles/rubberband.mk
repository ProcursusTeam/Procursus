ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += rubberband
RUBBERBAND_VERSION    := 1.9.1
DEB_RUBBERBAND_V      ?= $(RUBBERBAND_VERSION)

rubberband-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://breakfastquay.com/files/releases/rubberband-$(RUBBERBAND_VERSION).tar.bz2
	$(call EXTRACT_TAR,rubberband-$(RUBBERBAND_VERSION).tar.bz2,rubberband-$(RUBBERBAND_VERSION),rubberband)
	mkdir -p $(BUILD_WORK)/rubberband/build

	echo -e "[host_machine]\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	system = 'darwin'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/rubberband/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/rubberband/.build_complete),)
rubberband:
	@echo "Using previously built rubberband."
else
rubberband: rubberband-setup libsamplerate libsndfile
	cd $(BUILD_WORK)/rubberband/build && meson \
		--cross-file cross.txt \
		..
	+DESTDIR=$(BUILD_STAGE)/rubberband ninja -C $(BUILD_WORK)/rubberband/build install
	+DESTDIR=$(BUILD_BASE) ninja -C $(BUILD_WORK)/rubberband/build install
	touch $(BUILD_WORK)/rubberband/.build_complete
endif

rubberband-package: rubberband-stage
	# rubberband.mk Package Structure
	rm -rf $(BUILD_DIST)/{rubberband-cli,librubberband{2,-dev}}
	mkdir -p $(BUILD_DIST)/rubberband-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/librubberband{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# rubberband.mk Prep rubberband-cli
	cp -a $(BUILD_STAGE)/rubberband/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/rubberband-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rubberband.mk Prep librubberband2
	cp -a $(BUILD_STAGE)/rubberband/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librubberband.2.dylib $(BUILD_DIST)/librubberband2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# rubberband.mk Prep librubberband-dev
	cp -a $(BUILD_STAGE)/rubberband/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(librubberband.2.dylib) $(BUILD_DIST)/librubberband-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/rubberband/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/librubberband-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rubberband.mk Sign
	$(call SIGN,rubberband-cli,general.xml)
	$(call SIGN,librubberband2,general.xml)

	# rubberband.mk Make .debs
	$(call PACK,rubberband-cli,DEB_RUBBERBAND_V)
	$(call PACK,librubberband2,DEB_RUBBERBAND_V)
	$(call PACK,librubberband-dev,DEB_RUBBERBAND_V)

	# rubberband.mk Build cleanup
	rm -rf $(BUILD_DIST)/{rubberband-cli,librubberband{2,-dev}}

.PHONY: rubberband rubberband-package
