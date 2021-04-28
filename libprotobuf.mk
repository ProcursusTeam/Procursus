ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libprotobuf
LIBPROTOBUF_VERSION := 3.14.0
DEB_LIBPROTOBUF_V   ?= $(LIBPROTOBUF_VERSION)

libprotobuf-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/protocolbuffers/protobuf/releases/download/v$(LIBPROTOBUF_VERSION)/protobuf-cpp-$(LIBPROTOBUF_VERSION).tar.gz
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
		DESTDIR="$(BUILD_BASE)"
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf install \
		DESTDIR="$(BUILD_STAGE)/libprotobuf"
	touch $(BUILD_WORK)/libprotobuf/.build_complete
endif

libprotobuf-package: libprotobuf-stage
	# libprotobuf.mk Package Structure
	rm -rf $(BUILD_DIST)/libprotobuf{{,-lite}25,-dev} $(BUILD_DIST)/libprotoc{25,-dev} $(BUILD_DIST)/protobuf-compiler
	mkdir -p $(BUILD_DIST)/libprotobuf25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotobuf-lite25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/google/protobuf,lib} \
		$(BUILD_DIST)/libprotoc25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/google/protobuf,lib} \
		$(BUILD_DIST)/protobuf-compiler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libprotobuf.mk Prep libprotobuf25
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotobuf.25.dylib $(BUILD_DIST)/libprotobuf25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotobuf-lite25
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotobuf-lite.25.dylib $(BUILD_DIST)/libprotobuf-lite25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotobuf-dev
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libprotobuf.{a,dylib}} $(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf/!(compiler) $(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf

	# libprotobuf.mk Prep libprotoc25
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotoc.25.dylib $(BUILD_DIST)/libprotoc25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotoc-dev
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotoc.{a,dylib} $(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf/compiler $(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf

	# libprotobuf.mk Prep protobuf-compiler
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/protobuf-compiler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libprotobuf.mk Sign
	$(call SIGN,libprotobuf25,general.xml)
	$(call SIGN,libprotobuf-lite25,general.xml)
	$(call SIGN,libprotoc25,general.xml)
	$(call SIGN,protobuf-compiler,general.xml)

	# libprotobuf.mk Make .debs
	$(call PACK,libprotobuf25,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf-lite25,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf-dev,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotoc25,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotoc-dev,DEB_LIBPROTOBUF_V)
	$(call PACK,protobuf-compiler,DEB_LIBPROTOBUF_V)

	# libprotobuf.mk Build cleanup
	rm -rf $(BUILD_DIST)/libprotobuf{{,-lite}25,-dev} $(BUILD_DIST)/libprotoc{25,-dev} $(BUILD_DIST)/protobuf-compiler

.PHONY: libprotobuf libprotobuf-package
