ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libfmt
LIBFMT_VERSION  := 7.1.3
DEB_LIBFMT_V    ?= $(LIBFMT_VERSION)

libfmt-setup: setup
	$(call GITHUB_ARCHIVE,fmtlib,fmt,$(LIBFMT_VERSION),$(LIBFMT_VERSION),libfmt)
	$(call EXTRACT_TAR,libfmt-$(LIBFMT_VERSION).tar.gz,fmt-$(LIBFMT_VERSION),libfmt)

ifneq ($(wildcard $(BUILD_WORK)/libfmt/.build_complete),)
libfmt:
	@echo "Using previously built libfmt."
else
libfmt: libfmt-setup
	cd $(BUILD_WORK)/libfmt && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS=ON \
		-DFMT_TEST=OFF
	+$(MAKE) -C $(BUILD_WORK)/libfmt
	+$(MAKE) -C $(BUILD_WORK)/libfmt install \
		DESTDIR="$(BUILD_STAGE)/libfmt"
	+$(MAKE) -C $(BUILD_WORK)/libfmt install \
		DESTDIR="$(BUILD_BASE)"

	touch $(BUILD_WORK)/libfmt/.build_complete
endif

libfmt-package: libfmt-stage
	# libfmt.mk Package Structure
	rm -rf $(BUILD_DIST)/libfmt{7,-dev}
	mkdir -p $(BUILD_DIST)/libfmt{7,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libfmt.mk Prep libfmt7
	cp -a $(BUILD_STAGE)/libfmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfmt.{7,$(LIBFMT_VERSION)}.dylib $(BUILD_DIST)/libfmt7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libfmt.mk Prep libfmt-dev
	cp -a $(BUILD_STAGE)/libfmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libfmt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libfmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfmt.dylib $(BUILD_DIST)/libfmt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libfmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libfmt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libfmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake $(BUILD_DIST)/libfmt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libfmt.mk Sign
	$(call SIGN,libfmt7,general.xml)

	# libfmt.mk Make .debs
	$(call PACK,libfmt7,DEB_LIBFMT_V)
	$(call PACK,libfmt-dev,DEB_LIBFMT_V)

	# libfmt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfmt{7,-dev}

.PHONY: libfmt libfmt-package
