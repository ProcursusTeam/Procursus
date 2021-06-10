ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libsndfile
LIBSNDFILE_VERSION := 1.0.31
DEB_LIBSNDFILE_V   ?= $(LIBSNDFILE_VERSION)

libsndfile-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://github.com/libsndfile/libsndfile/releases/download/$(LIBSNDFILE_VERSION)/libsndfile-$(LIBSNDFILE_VERSION).tar.bz2
	$(call EXTRACT_TAR,libsndfile-$(LIBSNDFILE_VERSION).tar.bz2,libsndfile-$(LIBSNDFILE_VERSION),libsndfile)

ifneq ($(wildcard $(BUILD_WORK)/libsndfile/.build_complete),)
libsndfile:
	@echo "Using previously built libsndfile."
else
libsndfile: libsndfile-setup flac libogg libvorbis libopus
	cd $(BUILD_WORK)/libsndfile && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libsndfile
	+$(MAKE) -C $(BUILD_WORK)/libsndfile install \
		DESTDIR=$(BUILD_STAGE)/libsndfile
	+$(MAKE) -C $(BUILD_WORK)/libsndfile install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libsndfile/.build_complete
endif

libsndfile-package: libsndfile-stage
	# libsndfile.mk Package Structure
	rm -rf $(BUILD_DIST)/libsndfile1{,-dev} \
		$(BUILD_DIST)/sndfile-programs
	mkdir -p $(BUILD_DIST)/libsndfile1{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/sndfile-programs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libsndfile.mk Prep libsndfile1
	cp -a $(BUILD_STAGE)/libsndfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsndfile.1*.dylib $(BUILD_DIST)/libsndfile1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsndfile.mk Prep libsndfile1-dev
	cp -a $(BUILD_STAGE)/libsndfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsndfile.{dylib,a} $(BUILD_DIST)/libsndfile1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsndfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libsndfile1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsndfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsndfile1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsndfile.mk Prep sndfile-programs
	cp -a $(BUILD_STAGE)/libsndfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/sndfile-programs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libsndfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/sndfile-programs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libsndfile.mk Sign
	$(call SIGN,libsndfile1,general.xml)
	$(call SIGN,sndfile-programs,general.xml)

	# libsndfile.mk Make .debs
	$(call PACK,libsndfile1,DEB_LIBSNDFILE_V)
	$(call PACK,libsndfile1-dev,DEB_LIBSNDFILE_V)
	$(call PACK,sndfile-programs,DEB_LIBSNDFILE_V)

	# libsndfile.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsndfile1{,-dev} \
		$(BUILD_DIST)/sndfile-programs

.PHONY: libsndfile libsndfile-package
