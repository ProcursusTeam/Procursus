ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xterm
XTERM_VERSION := 367
DEB_XTERM_V   ?= $(XTERM_VERSION)

xterm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://invisible-mirror.net/archives/xterm/xterm-$(XTERM_VERSION).tgz
	$(call EXTRACT_TAR,xterm-$(XTERM_VERSION).tgz,xterm-$(XTERM_VERSION),xterm)

ifneq ($(wildcard $(BUILD_WORK)/xterm/.build_complete),)
xterm:
	@echo "Using previously built xterm."
else
xterm: xterm-setup libx11 libxau libxmu xorgproto xbitmaps gettext ncurses libxaw libxt libxext libxinerama libice libxpm xbitmaps fontconfig freetype
	cd $(BUILD_WORK)/xterm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xterm
	+$(MAKE) -C $(BUILD_WORK)/xterm install \
		DESTDIR=$(BUILD_STAGE)/xterm
	touch $(BUILD_WORK)/xterm/.build_complete
endif

xterm-package: xterm-stage
# xterm.mk Package Structure
	rm -rf $(BUILD_DIST)/xterm
	
# xterm.mk Prep xterm
	cp -a $(BUILD_STAGE)/xterm $(BUILD_DIST)
	
# xterm.mk Sign
	$(call SIGN,xterm,general.xml)
	
# xterm.mk Make .debs
	$(call PACK,xterm,DEB_XTERM_V)
	
# xterm.mk Build cleanup
	rm -rf $(BUILD_DIST)/xterm

.PHONY: xterm xterm-package
