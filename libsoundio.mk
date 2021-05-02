ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libsoundio
LIBSOUNDIO_VERSION := 2.0.0
DEB_LIBSOUNDIO_V   ?= $(LIBSOUNDIO_VERSION)

libsoundio-setup: setup
	$(call GITHUB_ARCHIVE,andrewrk,libsoundio,$(LIBSOUNDIO_VERSION),$(LIBSOUNDIO_VERSION))
	$(call EXTRACT_TAR,libsoundio-$(LIBSOUNDIO_VERSION).tar.gz,libsoundio-$(LIBSOUNDIO_VERSION),libsoundio)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,libsoundio-ios,libsoundio,-p1)
endif

ifneq ($(wildcard $(BUILD_WORK)/libsoundio/.build_complete),)
libsoundio:
	@echo "Using previously built libsoundio."
else
libsoundio: libsoundio-setup
	mkdir -p $(BUILD_WORK)/libsoundio/build
	# TODO: enable pulseaudio
	cd $(BUILD_WORK)/libsoundio/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_SHARED_LINKER_FLAGS="-framework CoreAudio -framework AudioToolbox" \
		-DBUILD_DYNAMIC_LIBS=1 \
		-DBUILD_TESTS=OFF \
		-DENABLE_JACK=OFF \
		-DENABLE_PULSEAUDIO=OFF \
		-DENABLE_ALSA=OFF \
		-DENABLE_COREAUDIO=ON \
		-DENABLE_WASAPI=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/libsoundio/build
	+$(MAKE) -C $(BUILD_WORK)/libsoundio/build install \
		DESTDIR=$(BUILD_STAGE)/libsoundio
	+$(MAKE) -C $(BUILD_WORK)/libsoundio/build install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libsoundio/.build_complete
endif

libsoundio-package: libsoundio-stage
	# libsoundio.mk Package Structure
	rm -rf \
		$(BUILD_DIST)/libsoundio{2,-dev} \
		$(BUILD_DIST)/libsoundio-progs
	mkdir -p \
		$(BUILD_DIST)/libsoundio{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libsoundio-progs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsoundio.mk Prep libsoundio2
	cp -a $(BUILD_STAGE)/libsoundio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsoundio.2*.dylib $(BUILD_DIST)/libsoundio2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libsoundio.mk Prep libsoundio-dev
	cp -a $(BUILD_STAGE)/libsoundio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsoundio.{dylib,a} $(BUILD_DIST)/libsoundio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsoundio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsoundio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsoundio.mk Prep libsoundio-progs
	cp -a $(BUILD_STAGE)/libsoundio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libsoundio-progs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsoundio.mk Sign
	$(call SIGN,libsoundio2,audio.xml)
	$(call SIGN,libsoundio-progs,audio.xml)

	# libsoundio.mk Make .debs
	$(call PACK,libsoundio2,DEB_LIBSOUNDIO_V)
	$(call PACK,libsoundio-dev,DEB_LIBSOUNDIO_V)
	$(call PACK,libsoundio-progs,DEB_LIBSOUNDIO_V)

	# libsoundio.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsoundio{2,-dev} \
		$(BUILD_DIST)/libsoundio-progs

.PHONY: libsoundio libsoundio-package
