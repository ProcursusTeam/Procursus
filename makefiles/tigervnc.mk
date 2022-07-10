ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += tigervnc
TIGERVNC_COMMIT     := 8b9cc06c9a918af1831bd50ed2662c253d6d1e20
TIGERVNC_VERSION    := 1.12.0+git20220629.$(shell echo $(TIGERVNC_COMMIT) | cut -c -7)
XORG_VERSION        := 21.1.1
DEB_TIGERVNC_V      ?= $(TIGERVNC_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
TIGERVNC_CONFIGURE_FLAGS := --disable-mitshm
else
TIGERVNC_CONFIGURE_FLAGS := --enable-mitshm
endif

tigervnc-setup: setup
<<<<<<< HEAD
	$(call GITHUB_ARCHIVE,TigerVNC,tigervnc,$(TIGERVNC_COMMIT),$(TIGERVNC_COMMIT))
	$(call EXTRACT_TAR,tigervnc-$(TIGERVNC_COMMIT).tar.gz,tigervnc-$(TIGERVNC_COMMIT),tigervnc)
=======
	wget2 -q -nc -P $(BUILD_SOURCE) https://github.com/TigerVNC/tigervnc/archive/refs/tags/v1.11.0.tar.gz
	$(call EXTRACT_TAR,v$(TIGERVNC_VERSION).tar.gz,tigervnc-$(TIGERVNC_VERSION),tigervnc)
>>>>>>> upstream/main
	$(call DO_PATCH,tigervnc,tigervnc,-p1)

ifneq ($(wildcard $(BUILD_WORK)/tigervnc/.build_complete),)
tigervnc:
	@echo "Using previously built tigervnc."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
tigervnc: tigervnc-setup libmd libx11 libxau libxmu xorgproto libpixman gnutls libjpeg-turbo libxdamage libxfixes libxtst libxrandr libxfont2 mesa libgeneral libxdmcp libxdamage  libxv libxvmc libxcomposite libxxf86dga xorg-server
else
tigervnc: tigervnc-setup libmd libx11 libxau libxmu xorgproto libpixman gnutls libjpeg-turbo libxdamage libxfixes libxtst libxrandr libxfont2 mesa libgeneral libxdmcp libxdamage libxv libxvmc libxcomposite libxxf86dga openpam xorg-server
endif
	cd $(BUILD_WORK)/tigervnc && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_VIEWER=FALSE \
		-DUSE_JAVA=FALSE \
		-DGETTEXT_MSGFMT_EXECUTABLE=$(shell command -v msgfmt)
	+$(MAKE) -i -C $(BUILD_WORK)/tigervnc
	+$(MAKE) -i -C $(BUILD_WORK)/tigervnc install \
		DESTDIR=$(BUILD_STAGE)/tigervnc
<<<<<<< HEAD
	cd $(BUILD_WORK)/tigervnc && tar -xf $(BUILD_WORK)/xorg-server/xorg-server-$(XORG-SERVER_VERSION).tar.xz
	cp -a $(BUILD_WORK)/tigervnc/xorg-server-$(XORG-SERVER_VERSION)/* $(BUILD_WORK)/tigervnc/unix/xserver/
=======
	wget2 -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive//individual/xserver/xorg-server-$(XORG-SERVER_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xorg-server-$(XORG-SERVER_VERSION).tar.gz)
	$(call EXTRACT_TAR,xorg-server-$(XORG-SERVER_VERSION).tar.gz,xorg-server-$(XORG-SERVER_VERSION),xorg-server-vnc)
	cp -R $(BUILD_WORK)/xorg-server-vnc/. $(BUILD_WORK)/tigervnc/unix/xserver
	sed -i 's/__APPLE__/__PEAR__/' $(BUILD_WORK)/tigervnc/unix/xserver/miext/rootless/rootlessWindow.c
>>>>>>> upstream/main
	cd $(BUILD_WORK)/tigervnc/unix/xserver && patch -p1 < $(BUILD_WORK)/tigervnc/unix/xserver$(XORG_VERSION).patch && \
	export ACLOCAL='aclocal -I $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal' && \
	export gcc=cc && autoreconf -fiv && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-pic \
		--without-dtrace \
		--disable-static \
		--disable-dri \
		--enable-xinerama \
		--disable-xvfb \
		--disable-xnest \
		--disable-xorg \
		--disable-xwin \
		--disable-xephyr \
		--disable-xquartz \
		--disable-kdrive \
		--disable-config-dbus \
		--disable-config-hal \
		--disable-config-udev \
		--disable-dri2 \
		--enable-install-libxf86config \
		--disable-glx \
		--with-sha1=CommonCrypto \
		--with-default-font-path="catalogue:$(MEMO_PREFIX)/etc/X11/fontpath.d,built-ins" \
		--with-fontdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/X11/fonts \
		--with-xkb-path=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/X11/xkb \
		--with-xkb-output=$(MEMO_PREFIX)/var/lib/xkb \
		--with-xkb-bin-directory=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		--with-serverconfig-path=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg \
		--with-vendor-name='Procursus Team' \
		--with-vendor-name-short='Procursus' \
		--with-vendor-web='https://github.com/ProcursusTeam/Procursus' \
		$(TIGERVNC_CONFIGURE_FLAGS) \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pixman-1" \
		LIBS=-lz
	+cd $(BUILD_WORK)/tigervnc/unix/xserver && $(MAKE) TIGERVNC_SRCDIR=$(BUILD_WORK)/tigervnc
	+$(MAKE) -C $(BUILD_WORK)/tigervnc/unix/xserver install \
		DESTDIR=$(BUILD_STAGE)/tigervnc
	rm -f $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/protocol.txt
	rm -f $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man1/Xserver.1
	$(call AFTER_BUILD,copy)
endif

tigervnc-package: tigervnc-stage
# tigervnc.mk Package Structure
	rm -rf $(BUILD_DIST)/tigervnc-{standalone-server,xorg-extension,scraping-server,common}
	mkdir -p $(BUILD_DIST)/tigervnc-standalone-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/tigervnc-common/{$(MEMO_PREFIX)/etc,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin} \
		$(BUILD_DIST)/tigervnc-scraping-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{libexec,bin} \
		$(BUILD_DIST)/tigervnc-xorg-extension/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/extensions \

# tigervnc.mk Prep tigervnc-standalone-server
	rm -rf $(BUILD_STAGE)/tigervnc/usr/lib/xorg/protocol.txt
	rm -rf $(BUILD_STAGE)/tigervnc/usr/share/man/man1/Xserver.1
	cp -a $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/Xvnc \
		$(BUILD_DIST)/tigervnc-standalone-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

# tigervnc.mk Prep tigervnc-common
	cp -a $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)/etc $(BUILD_DIST)/tigervnc-common$(MEMO_PREFIX)/etc
	cp -a $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{vncconfig,vncpasswd} \
		$(BUILD_DIST)/tigervnc-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

# tigervnc.mk Prep tigervnc-xorg-extension
	cp -a $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/extensions/libvnc.so \
		$(BUILD_DIST)/tigervnc-xorg-extension/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xorg/modules/extensions

# tigervnc.mk Prep tigervnc-scraping-server
	cp -a $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/x0vncserver \
		$(BUILD_DIST)/tigervnc-scraping-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	cp -a $(BUILD_STAGE)/tigervnc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec \
		$(BUILD_DIST)/tigervnc-scraping-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec

# tigervnc.mk Sign
	$(call SIGN,tigervnc-standalone-server,general.xml)
	$(call SIGN,tigervnc-xorg-extension,general.xml)
	$(call SIGN,tigervnc-scraping-server,general.xml)
	$(call SIGN,tigervnc-common,general.xml)

# tigervnc.mk Make .debs
	$(call PACK,tigervnc-standalone-server,DEB_TIGERVNC_V)
	$(call PACK,tigervnc-xorg-extension,DEB_TIGERVNC_V)
	$(call PACK,tigervnc-scraping-server,DEB_TIGERVNC_V)
	$(call PACK,tigervnc-common,DEB_TIGERVNC_V)

# tigervnc.mk Build cleanup
	rm -rf $(BUILD_DIST)/tigervnc-{standalone-server,xorg-extension,scraping-server,common}

.PHONY: tigervnc tigervnc-package
