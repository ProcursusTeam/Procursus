ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += xorg-server
XORG-SERVER_VERSION := 21.0.99.901
DEB_XORG-SERVER_V   ?= $(XORG-SERVER_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
MITSHM := --disable-mitshm
else
MITSHM := --enable-mitshm
endif

xorg-server-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive//individual/xserver/xorg-server-$(XORG-SERVER_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xorg-server-$(XORG-SERVER_VERSION).tar.gz)
	$(call EXTRACT_TAR,xorg-server-$(XORG-SERVER_VERSION).tar.gz,xorg-server-$(XORG-SERVER_VERSION),xorg-server)
	$(call DO_PATCH,xorg-server,xorg-server,-p1)
	sed -i 's/__APPLE__/__PEAR__/' $(BUILD_WORK)/xorg-server/miext/rootless/rootlessWindow.c

#   --enable-glamor needs GBM and libepoxy

ifneq ($(wildcard $(BUILD_WORK)/xorg-server/.build_complete),)
xorg-server:
	@echo "Using previously built xorg-server."
else
xorg-server: xorg-server-setup libmd libx11 libxau libxmu xorgproto font-util libpixman libpng16 mesa libxfont2 libxkbfile libxdamage libxt libxpm libxaw libxres libxext xcb-util xcb-util-renderutil xcb-util-image xcb-util-wm xcb-util-keysyms libdmx libxdmcp libxfixes libxi libxrender libxtst libxcvt
	cd $(BUILD_WORK)/xorg-server && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-xorg \
		--with-default-font-path \
		--enable-xephyr \
		--enable-xvfb \
		--enable-xnest \
		--enable-kdrive \
		--disable-glamor \
		--disable-xquartz \
		--with-sha1=libmd \
		--disable-glx \
		$(MITSHM) \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pixman-1"
	+$(MAKE) -C $(BUILD_WORK)/xorg-server
	+$(MAKE) -C $(BUILD_WORK)/xorg-server install \
		DESTDIR=$(BUILD_STAGE)/xorg-server
	$(call AFTER_BUILD,copy)
endif

xorg-server-package: xorg-server-stage
	# xorg-server.mk Package Structure
	rm -rf $(BUILD_DIST)/xserver-xorg-{core,dev} $(BUILD_DIST)/{xvfb,xnest} \
		$(BUILD_DIST)/xserver-{common,xephyr}

	mkdir -p $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/xserver-xephyr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/xserver-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/xorg,share/man/man1,local} \
		$(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/xorg/modules/input,share/man/{man5,man1}} \
		$(BUILD_DIST)/xserver-xorg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/{pkgconfig,xorg/modules/input},share/aclocal} \
		$(BUILD_DIST)/xvfb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/xnest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	

	# xorg-server.mk Prep xserver-xephyr
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/Xephyr $(BUILD_DIST)/xserver-xephyr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/Xephyr.1.zst $(BUILD_DIST)/xserver-xephyr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# xorg-server.mk Prep xserver-xorg-core
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/X $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/Xorg $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gtf $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/Xorg.1.zst $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gtf.1.zst $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/xorg.conf.5.zst $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/xorg.conf.d.5.zst $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/*.so $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/input/*.so $(BUILD_DIST)/xserver-xorg-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/input/

	# xorg-server.mk Prep xvfb
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/Xvfb $(BUILD_DIST)/xvfb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/Xvfb.1.zst $(BUILD_DIST)/xvfb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# xorg-server.mk Prep xserver-common
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/protocol.txt $(BUILD_DIST)/xserver-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local $(BUILD_DIST)/xserver-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)local

	# xorg-server.mk Prep xnest
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/Xnest $(BUILD_DIST)/xnest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/Xnest.1.zst $(BUILD_DIST)/xnest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# xorg-server.mk Prep xserver-xorg-dev
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/xserver-xorg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/xorg-server.pc $(BUILD_DIST)/xserver-xorg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal/xorg-server.m4 $(BUILD_DIST)/xserver-xorg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/*.a $(BUILD_DIST)/xserver-xorg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/
	cp -a $(BUILD_STAGE)/xorg-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/input/*.a $(BUILD_DIST)/xserver-xorg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/input/

	# xorg-server.mk Sign
	$(call SIGN,xnest,general.xml)
	$(call SIGN,xserver-xephyr,general.xml)
	$(call SIGN,xvfb,general.xml)
	$(call SIGN,xserver-xorg-core,general.xml)
	
	# xorg-server.mk Make .debs
	$(call PACK,xserver-xorg-core,DEB_XORG-SERVER_V)
	$(call PACK,xvfb,DEB_XORG-SERVER_V)
	$(call PACK,xserver-xephyr,DEB_XORG-SERVER_V)
	$(call PACK,xnest,DEB_XORG-SERVER_V)
	$(call PACK,xserver-xorg-dev,DEB_XORG-SERVER_V)
	$(call PACK,xserver-common,DEB_XORG-SERVER_V)
	
	# xorg-server.mk Build cleanup
	rm -rf $(BUILD_DIST)/xserver-xorg-{core,dev} $(BUILD_DIST)/{xvfb,xnest} \
		$(BUILD_DIST)/xserver-{common,xephyr}

.PHONY: xorg-server xorg-server-package
