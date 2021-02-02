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
	$(call DO_PATCH,xcb-proto,xcb-proto,-p1)

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
		--disable-static \
		am_cv_python_pythondir=/usr/lib/python3/dist-packages \
		PYTHON=/usr/bin/python3
	+$(MAKE) -C $(BUILD_WORK)/xcb-proto install \
		DESTDIR=$(BUILD_STAGE)/xcb-proto
	+$(MAKE) -C $(BUILD_WORK)/xcb-proto install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xcb-proto/.build_complete
endif


xcb-proto-package: xcb-proto-stage
	rm -rf $(BUILD_DIST)/{xcb-proto,python3-xcbgen}
	mkdir -p $(BUILD_DIST)/xcb-proto/usr/lib \
		$(BUILD_DIST)/python3-xcbgen/usr/lib
	
	# xcb-proto.mk Prep xcb-proto
	cp -a $(BUILD_STAGE)/xcb-proto/usr/lib/pkgconfig $(BUILD_DIST)/xcb-proto/usr/lib
	cp -a $(BUILD_STAGE)/xcb-proto/usr/share $(BUILD_DIST)/xcb-proto/usr

	# xcb-proto.mk Prep python3-xcbgen
	cp -a $(BUILD_STAGE)/xcb-proto/usr/lib/python3 $(BUILD_DIST)/python3-xcbgen/usr/lib
	rm -f $(BUILD_DIST)/python3-xcbgen/usr/lib/python3/dist-packages/xcbgen/!(*.py)
	
	# xcb-proto.mk Make .debs
	$(call PACK,xcb-proto,DEB_XCBPROTO_V)
	$(call PACK,python3-xcbgen,DEB_XCBPROTO_V)
	
	# xcb-proto.mk Build cleanup
	rm -rf $(BUILD_DIST)/{xcb-proto,python3-xcbgen}

.PHONY: xcb-proto xcb-proto-package
