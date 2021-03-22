ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libxdmcp
LIBXDMCP_VERSION := 1.1.3
DEB_LIBXDMCP_V   ?= $(LIBXDMCP_VERSION)

libxdmcp-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXdmcp-$(LIBXDMCP_VERSION).tar.bz2
	$(call EXTRACT_TAR,libXdmcp-$(LIBXDMCP_VERSION).tar.bz2,libXdmcp-$(LIBXDMCP_VERSION),libxdmcp)

ifneq ($(wildcard $(BUILD_WORK)/libxdmcp/.build_complete),)
libxdmcp:
	@echo "Using previously built libxdmcp."
else
libxdmcp: libxdmcp-setup xorgproto
	cd $(BUILD_WORK)/libxdmcp && ./configure \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var \
		--enable-docs=no
	+$(MAKE) -C $(BUILD_WORK)/libxdmcp install \
		DESTDIR="$(BUILD_STAGE)/libxdmcp"
	+$(MAKE) -C $(BUILD_WORK)/libxdmcp install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libxdmcp/.build_complete
endif

libxdmcp-package: libxdmcp-stage
	# libxdmcp.mk Package Structure
	rm -rf $(BUILD_DIST)/libxdmcp{6,-dev}
	mkdir -p $(BUILD_DIST)/libxdmcp{6,-dev}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# libxdmcp.mk Prep libxdmcp6
	cp -a $(BUILD_STAGE)/libxdmcp/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libXdmcp.6.dylib $(BUILD_DIST)/libxdmcp6/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# libxdmcp.mk Prep libxdmcp-dev
	cp -a $(BUILD_STAGE)/libxdmcp/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/!(libXdmcp.6.dylib) $(BUILD_DIST)/libxdmcp-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	cp -a $(BUILD_STAGE)/libxdmcp/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/libxdmcp-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)

	# libxdmcp.mk Sign
	$(call SIGN,libxdmcp6,general.xml)

	# libxdmcp.mk Make .debs
	$(call PACK,libxdmcp6,DEB_LIBXDMCP_V)
	$(call PACK,libxdmcp-dev,DEB_LIBXDMCP_V)

	# libxdmcp.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxdmcp{6,-dev}

.PHONY: libxdmcp libxdmcp-package
