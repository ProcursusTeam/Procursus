ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

# Update the control file for the library and dev package when bumping the version

SUBPROJECTS   += cmark
CMARK_VERSION := 0.29.0
DEB_CMARK_V   ?= $(CMARK_VERSION)

cmark-setup: setup
	$(call GITHUB_ARCHIVE,commonmark,cmark,$(CMARK_VERSION),$(CMARK_VERSION))
	$(call EXTRACT_TAR,cmark-$(CMARK_VERSION).tar.gz,cmark-$(CMARK_VERSION),cmark)

ifneq ($(wildcard $(BUILD_WORK)/cmark/.build_complete),)
cmark:
	@echo "Using previously built cmark."
else
cmark: cmark-setup
	mkdir $(BUILD_WORK)/cmark/build
	cd $(BUILD_WORK)/cmark/build && cmake .. \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMARK_TESTS=OFF \
		.
	+$(MAKE) -C $(BUILD_WORK)/cmark/build
	+$(MAKE) -C $(BUILD_WORK)/cmark/build install \
		DESTDIR="$(BUILD_STAGE)/cmark"
	+$(MAKE) -C $(BUILD_WORK)/cmark/build install \
		DESTDIR="$(BUILD_BASE)"

	touch $(BUILD_WORK)/cmark/.build_complete
endif

cmark-package: cmark-stage
	# cmark.mk Package Structure
	rm -rf $(BUILD_DIST)/cmark \
		$(BUILD_DIST)/libcmark{$(CMARK_VERSION),-dev}
	mkdir -p $(BUILD_DIST)/{cmark,libcmark-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libcmark{$(CMARK_VERSION),-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# cmark.mk Prep cmark
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# cmark.mk Prep libcmark$(CMARK_VERSION)
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcmark.$(CMARK_VERSION).dylib $(BUILD_DIST)/libcmark$(CMARK_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# cmark.mk Prep libcmark-dev
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcmark-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcmark.{dylib,a} $(BUILD_DIST)/libcmark-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libcmark-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake $(BUILD_DIST)/libcmark-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/cmark/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libcmark-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# cmark.mk Sign
	$(call SIGN,cmark,general.xml)
	$(call SIGN,libcmark$(CMARK_VERSION),general.xml)

	# cmark.mk Make .debs
	$(call PACK,cmark,DEB_CMARK_V)
	$(call PACK,libcmark$(CMARK_VERSION),DEB_CMARK_V)
	$(call PACK,libcmark-dev,DEB_CMARK_V)

	# cmark.mk Build cleanup
	rm -rf $(BUILD_DIST)/cmark \
		$(BUILD_DIST)/libcmark{$(CMARK_VERSION),-dev}

.PHONY: cmark cmark-package
