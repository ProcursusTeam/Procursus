ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += rubberband
RUBBERBAND_VERSION    := 1.9.0
DEB_RUBBERBAND_V      ?= $(RUBBERBAND_VERSION)-1

rubberband-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://breakfastquay.com/files/releases/rubberband-$(RUBBERBAND_VERSION).tar.bz2
	$(call EXTRACT_TAR,rubberband-$(RUBBERBAND_VERSION).tar.bz2,rubberband-$(RUBBERBAND_VERSION),rubberband)
	$(call DO_PATCH,rubberband,rubberband,-p1)
	mv "$(BUILD_WORK)/rubberband/Makefile.osx" $(BUILD_WORK)/rubberband/Makefile

ifneq ($(wildcard $(BUILD_WORK)/rubberband/.build_complete),)
rubberband:
	@echo "Using previously built rubberband."
else
rubberband: rubberband-setup libsamplerate libsndfile
	+$(MAKE) -C $(BUILD_WORK)/rubberband \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CC="$(CC)" \
		CXX="$(CXX)" \
		ARG_CXXFLAGS="$(CXXFLAGS)" \
		ARG_CFLAGS="$(CFLAGS)" \
		ARG_LDFLAGS="$(LDFLAGS)" \
		AR="$(AR)"

	+$(MAKE) -C $(BUILD_WORK)/rubberband install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/rubberband"
	+$(MAKE) -C $(BUILD_WORK)/rubberband install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_BASE)"

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
	cp -a $(BUILD_STAGE)/rubberband/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librubberband.2{,.1.2}.dylib $(BUILD_DIST)/librubberband2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# rubberband.mk Prep librubberband-dev
	cp -a $(BUILD_STAGE)/rubberband/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,librubberband.{dylib,a}} $(BUILD_DIST)/librubberband-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
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
