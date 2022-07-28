ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libprotobuf
LIBPROTOBUF_VERSION := 3.21.2
DEB_LIBPROTOBUF_V   ?= $(LIBPROTOBUF_VERSION)

libprotobuf-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/protocolbuffers/protobuf/releases/download/v$(shell echo $(LIBPROTOBUF_VERSION) | cut -d. -f2-)/protobuf-cpp-$(LIBPROTOBUF_VERSION).tar.gz)
	$(call EXTRACT_TAR,protobuf-cpp-$(LIBPROTOBUF_VERSION).tar.gz,protobuf-$(LIBPROTOBUF_VERSION),libprotobuf)

ifneq ($(wildcard $(BUILD_WORK)/libprotobuf/.build_complete),)
libprotobuf:
	@echo "Using previously built libprotobuf."
else
libprotobuf: libprotobuf-setup
	cd $(BUILD_WORK)/libprotobuf && ./autogen.sh
	cd $(BUILD_WORK)/libprotobuf && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf install \
		DESTDIR="$(BUILD_STAGE)/libprotobuf"
	$(call AFTER_BUILD,copy)
endif

libprotobuf-package: libprotobuf-stage
	# libprotobuf.mk Package Structure
	rm -rf $(BUILD_DIST)/libprotobuf{{,-lite}32,-dev} $(BUILD_DIST)/libprotoc{32,-dev} $(BUILD_DIST)/protobuf-compiler
	mkdir -p $(BUILD_DIST)/libprotobuf32/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotobuf-lite32/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/google/protobuf,lib} \
		$(BUILD_DIST)/libprotoc32/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/google/protobuf,lib} \
		$(BUILD_DIST)/protobuf-compiler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libprotobuf.mk Prep libprotobuf32
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotobuf.32.dylib $(BUILD_DIST)/libprotobuf32/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotobuf-lite32
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotobuf-lite.32.dylib $(BUILD_DIST)/libprotobuf-lite32/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotobuf-dev
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libprotobuf.{a,dylib}} $(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf/!(compiler) $(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf

	# libprotobuf.mk Prep libprotoc32
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotoc.32.dylib $(BUILD_DIST)/libprotoc32/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotoc-dev
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotoc.{a,dylib} $(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf/compiler $(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf

	# libprotobuf.mk Prep protobuf-compiler
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/protobuf-compiler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libprotobuf.mk Sign
	$(call SIGN,libprotobuf32,general.xml)
	$(call SIGN,libprotobuf-lite32,general.xml)
	$(call SIGN,libprotoc32,general.xml)
	$(call SIGN,protobuf-compiler,general.xml)

	# libprotobuf.mk Make .debs
	$(call PACK,libprotobuf32,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf-lite32,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf-dev,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotoc32,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotoc-dev,DEB_LIBPROTOBUF_V)
	$(call PACK,protobuf-compiler,DEB_LIBPROTOBUF_V)

	# libprotobuf.mk Build cleanup
	rm -rf $(BUILD_DIST)/libprotobuf{{,-lite}32,-dev} $(BUILD_DIST)/libprotoc{32,-dev} $(BUILD_DIST)/protobuf-compiler

.PHONY: libprotobuf libprotobuf-package
