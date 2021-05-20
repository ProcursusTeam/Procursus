ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xf86-video-dummy
DUMMY_VERSION := 0.3.8
DEB_DUMMY_V   ?= $(DUMMY_VERSION)

xf86-video-dummy-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gitlab.freedesktop.org/xorg/driver/xf86-video-dummy/-/archive/xf86-video-dummy-0.3.8/xf86-video-dummy-xf86-video-dummy-0.3.8.tar.gz
	$(call EXTRACT_TAR,xf86-video-dummy-xf86-video-dummy-$(DUMMY_VERSION).tar.gz,xf86-video-dummy-xf86-video-dummy-$(DUMMY_VERSION),xf86-video-dummy)

ifneq ($(wildcard $(BUILD_WORK)/xf86-video-dummy/.build_complete),)
xf86-video-dummy:
	@echo "Using previously built xf86-video-dummy."
else
xf86-video-dummy: xf86-video-dummy-setup xorg-server libpixman
	cd $(BUILD_WORK)/xf86-video-dummy && ./autogen.sh -C \
	$(DEFAULT_CONFIGURE_FLAGS) \
	CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{pixman-1,xorg}"
	+$(MAKE) -C $(BUILD_WORK)/xf86-video-dummy
	+$(MAKE) -C $(BUILD_WORK)/xf86-video-dummy install \
		DESTDIR=$(BUILD_STAGE)/xserver-xorg-video-dummy
	touch $(BUILD_WORK)/xf86-video-dummy/.build_complete
endif

xf86-video-dummy-package: xf86-video-dummy-stage
# xf86-video-dummy.mk Package Structure
	rm -rf $(BUILD_DIST)/xserver-xorg-video-dummy
	
# xf86-video-dummy.mk Prep xf86-video-dummy
	cp -a $(BUILD_STAGE)/xserver-xorg-video-dummy $(BUILD_DIST)

# xf86-video-dummy.mk Sign
	$(call SIGN,xserver-xorg-video-dummy,general.xml)
	
# xf86-video-dummy.mk Make .debs
	$(call PACK,xserver-xorg-video-dummy,DEB_DUMMY_V)
	
# xf86-video-dummy.mk Build cleanup
	rm -rf $(BUILD_DIST)/xserver-xorg-video-dummy

.PHONY: xf86-video-dummy xf86-video-dummy-package
