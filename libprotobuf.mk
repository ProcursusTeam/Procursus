ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libprotobuf
LIBPROTOBUF_VERSION := 3.12.3
DEB_LIBPROTOBUF_V   ?= $(LIBPROTOBUF_VERSION)

libprotobuf-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/protocolbuffers/protobuf/releases/download/v3.12.3/protobuf-cpp-$(LIBPROTOBUF_VERSION).tar.gz
	$(call EXTRACT_TAR,protobuf-cpp-$(LIBPROTOBUF_VERSION).tar.gz,protobuf-$(LIBPROTOBUF_VERSION),libprotobuf)

ifneq ($(wildcard $(BUILD_WORK)/libprotobuf/.build_complete),)
libprotobuf:
	@echo "Using previously built libprotobuf."
else
libprotobuf: libprotobuf-setup
	cd $(BUILD_WORK)/libprotobuf && ./autogen.sh
	cd $(BUILD_WORK)/libprotobuf && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf install \
		DESTDIR=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf install \
		DESTDIR=$(BUILD_STAGE)/libprotobuf/
	touch $(BUILD_WORK)/libprotobuf/.build_complete
endif

libprotobuf-package: libprotobuf-stage
	# libprotobuf.mk Package Structure
	rm -rf $(BUILD_DIST)/{libprotobuf,libprotobuf-dev}
	mkdir -p $(BUILD_DIST)/{libprotobuf/usr,libprotobuf-dev/usr/lib}

	# libprotobuf.mk Prep libprotobuf
	cp -a $(BUILD_STAGE)/libprotobuf/usr/{lib/*.dylib,bin} $(BUILD_DIST)/libprotobuf/usr

	# libprotobuf.mk Prep libprotobuf-dev
	cp -a $(BUILD_STAGE)/libprotobuf/usr/lib/{pkgconfig,libprotoc.a,libprotoc.la} $(BUILD_DIST)/libprotobuf-dev/usr/lib
	cp -a $(BUILD_STAGE)/libprotobuf/usr/include $(BUILD_DIST)/libprotobuf-dev/usr

	# libprotobuf.mk Sign
	$(call SIGN,libprotobuf,general.xml)
	$(call SIGN,libprotobuf-dev,general.xml)
	
	# libprotobuf.mk Make .debs
	$(call PACK,libprotobuf,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf-dev,DEB_LIBPROTOBUF_V)
	
	# libprotobuf.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libprotobuf,libprotobuf-dev}

.PHONY: libprotobuf libprotobuf-package
