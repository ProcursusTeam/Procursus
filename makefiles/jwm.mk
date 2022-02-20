ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += jwm
JWM_VERSION := 2.3.7
DEB_JWM_V   ?= $(JWM_VERSION)

jwm-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://joewing.net/projects/jwm/releases/jwm-$(JWM_VERSION).tar.xz
	$(call EXTRACT_TAR,jwm-$(JWM_VERSION).tar.xz,jwm-$(JWM_VERSION),jwm)

ifneq ($(wildcard $(BUILD_WORK)/jwm/.build_complete),)
jwm:
	@echo "Using previously built jwm."
else
jwm: jwm-setup glib2.0 gettext libx11 freetype libxinerama cairo libxext libxmu libxpm libjpeg-turbo libpng16 libxrender libxft libfribidi
	cd $(BUILD_WORK)/jwm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-rsvg \
		--enable-xft \
		--enable-xrender \
		--enable-xmu \
		--enable-xpm \
		--enable-png \
		--enable-jpeg \
		--enable-cairo \
		--enable-fribidi \
		CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/freetype2 $(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/jwm
	+$(MAKE) -C $(BUILD_WORK)/jwm install \
		DESTDIR=$(BUILD_STAGE)/jwm
	$(call AFTER_BUILD)
endif

jwm-package: jwm-stage
	# jwm.mk Package Structure
	rm -rf $(BUILD_DIST)/jwm
	
	# jwm.mk Prep jwm
	cp -a $(BUILD_STAGE)/jwm $(BUILD_DIST)
	
	# jwm.mk Sign
	$(call SIGN,jwm,general.xml)
	
	# jwm.mk Make .debs
	$(call PACK,jwm,DEB_JWM_V)
	
	# jwm.mk Build cleanup
	rm -rf $(BUILD_DIST)/jwm

.PHONY: jwm jwm-package
