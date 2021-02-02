ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += xcb-proto
XCBPROTO_VERSION := 1.14.1
DEB_XCBPROTO_V   ?= $(XCBPROTO_VERSION)

xcb-proto-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://xorg.freedesktop.org/archive/individual/proto/xcb-proto-$(XCBPROTO_VERSION).tar.gz{,.sig}   
	$(call PGP_VERIFY,xcb-proto-$(XCBPROTO_VERSION).tar.gz)
	$(call EXTRACT_TAR,xcb-proto-$(XCBPROTO_VERSION).tar.gz,xcb-proto-$(XCBPROTO_VERSION),xcb-proto)

ifneq ($(wildcard $(BUILD_WORK)/xcb-proto/.build_complete),)
xcb-proto:
	@echo "Using previously built xcb-proto."
else
xcb-proto: xcb-proto-setup
	cd $(BUILD_WORK)/xcb-proto && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--disable-static
	+$(MAKE) -C $(BUILD_WORK)/xcb-proto install \
		DESTDIR=$(BUILD_STAGE)/xcb-proto
	+$(MAKE) -C $(BUILD_WORK)/xcb-proto install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xcb-proto/.build_complete
endif


xcb-proto-package: xcb-proto-stage
	rm -rf $(BUILD_DIST)/xorg-xcb-proto
	mkdir -p $(BUILD_DIST)/xorg-xcb-proto
	
	# xcb-proto.mk Prep xcb-proto
	cp -a $(BUILD_STAGE)/xcb-proto/usr $(BUILD_DIST)/xorg-xcb-proto

	# xcb-proto.mk Sign
	$(call SIGN,xorg-xcb-proto,general.xml)
	
	# xcb-proto.mk Make .debs
	$(call PACK,xorg-xcb-proto,DEB_XCBPROTO_V)
	
	# xcb-proto.mk Build cleanup
	rm -rf $(BUILD_DIST)/xorg-xcb-proto

.PHONY: xcb-proto xcb-proto-package
