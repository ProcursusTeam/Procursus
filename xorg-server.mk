ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += xorg-server
XORG-SERVER_VERSION := 1.20.10
DEB_XORG-SERVER_V   ?= $(XORG-SERVER_VERSION)

xorg-server-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive//individual/xserver/xorg-server-$(XORG-SERVER_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xorg-server-$(XORG-SERVER_VERSION).tar.gz)
	$(call EXTRACT_TAR,xorg-server-$(XORG-SERVER_VERSION).tar.gz,xorg-server-$(XORG-SERVER_VERSION),xorg-server)
	$(call DO_PATCH,xorg-server,xorg-server,-p1)
	$(SED) -i 's/__APPLE__/__PEAR__/' $(BUILD_WORK)/xorg-server/miext/rootless/rootlessWindow.c

#   --enable-glamor needs GBM and libepoxy

ifneq ($(wildcard $(BUILD_WORK)/xorg-server/.build_complete),)
xorg-server:
	@echo "Using previously built xorg-server."
else
xorg-server: xorg-server-setup libx11 libxau libxmu xorgproto font-util libpixman libpng16 mesa libxfont2 libxkbfile libxdamage libxt libxpm libxaw libxres libxext
	cd $(BUILD_WORK)/xorg-server && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-xorg \
		--with-default-font-path \
		--enable-dmx \
		--disable-glamor \
		--disable-xquartz \
		PKG_CONFIG="pkg-config --define-prefix"
		#--enable-xephyr \
		#--enable-kdrive
	$(SED) -i 's|panoramiX.\$$(OBJEXT)||' $(BUILD_WORK)/xorg-server/hw/dmx/Makefile
#   ^^ Wtf
	+$(MAKE) -C $(BUILD_WORK)/xorg-server
	+$(MAKE) -C $(BUILD_WORK)/xorg-server install \
		DESTDIR=$(BUILD_STAGE)/xorg-server
	+$(MAKE) -C $(BUILD_WORK)/xorg-server install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xorg-server/.build_complete
endif

xorg-server-package: xorg-server-stage
# xorg-server.mk Package Structure
	rm -rf $(BUILD_DIST)/xorg-server
	
# xorg-server.mk Prep xorg-server
	cp -a $(BUILD_STAGE)/xorg-server $(BUILD_DIST)
	
# xorg-server.mk Sign
	$(call SIGN,xorg-server,general.xml)
	
# xorg-server.mk Make .debs
	$(call PACK,xorg-server,DEB_xorg-server_V)
	
# xorg-server.mk Build cleanup
	rm -rf $(BUILD_DIST)/xorg-server

.PHONY: xorg-server xorg-server-package
