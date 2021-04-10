ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += lynx
LYNX_VERSION := 2.8.9
DEB_LYNX_V   ?= $(LYNX_VERSION)-3

lynx-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://invisible-mirror.net/archives/lynx/tarballs/lynx$(LYNX_VERSION)rel.1.tar.bz2{,.asc}
	$(call PGP_VERIFY,lynx$(LYNX_VERSION)rel.1.tar.bz2,asc)
	$(call EXTRACT_TAR,lynx$(LYNX_VERSION)rel.1.tar.bz2,lynx$(LYNX_VERSION)rel.1,lynx)
ifeq ($(UNAME),Darwin)
	$(SED) -i 's|#define socklen_t int|//#define socklen_t int|' $(BUILD_WORK)/lynx/WWW/Library/Implementation/www_tcp.h
endif

ifneq ($(wildcard $(BUILD_WORK)/lynx/.build_complete),)
lynx:
	@echo "Using previously built lynx."
else
lynx: lynx-setup ncurses libidn2 openssl gettext
	cd $(BUILD_WORK)/lynx && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-build-cc=cc \
		--with-ssl="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		--disable-echo \
		--enable-default-colors \
		--with-zlib \
		--with-bzlib \
		--enable-ipv6 \
		--enable-nls \
		--with-screen=ncursesw \
		--disable-config-info
	+$(MAKE) -C $(BUILD_WORK)/lynx
	+$(MAKE) -C $(BUILD_WORK)/lynx install \
		DESTDIR=$(BUILD_STAGE)/lynx
	touch $(BUILD_WORK)/lynx/.build_complete
endif

lynx-package: lynx-stage
	# lynx.mk Package Structure
	rm -rf $(BUILD_DIST)/lynx
	mkdir -p $(BUILD_DIST)/lynx

	# lynx.mk Prep lynx
	cp -a $(BUILD_STAGE)/lynx $(BUILD_DIST)

	# lynx.mk Sign
	$(call SIGN,lynx,general.xml)

	# lynx.mk Make .debs
	$(call PACK,lynx,DEB_LYNX_V)

	# lynx.mk Build cleanup
	rm -rf $(BUILD_DIST)/lynx

.PHONY: lynx lynx-package
