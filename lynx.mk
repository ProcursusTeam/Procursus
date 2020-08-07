ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += lynx
LYNX_VERSION := 2.8.9
DEB_LYNX_V   ?= $(LYNX_VERSION)-1

lynx-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://invisible-mirror.net/archives/lynx/tarballs/lynx$(LYNX_VERSION)rel.1.tar.gz
	$(call EXTRACT_TAR,lynx$(LYNX_VERSION)rel.1.tar.gz,lynx$(LYNX_VERSION)rel.1,lynx)

ifneq ($(wildcard $(BUILD_WORK)/lynx/.build_complete),)
lynx:
	@echo "Using previously built lynx."
else
lynx: lynx-setup ncurses libidn2 openssl
	cd $(BUILD_WORK)/lynx && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
    --sysconfdir=/etc \
    --with-ssl=/usr \
    --enable-nls \
    --mandir=/usr/share/man
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
	cp -a $(BUILD_STAGE)/lynx/usr $(BUILD_DIST)/lynx
	
	# lynx.mk Sign
	$(call SIGN,lynx,general.xml)
	
	# lynx.mk Make .debs
	$(call PACK,lynx,DEB_LYNX_V)
	
	# lynx.mk Build cleanup
	rm -rf $(BUILD_DIST)/lynx

.PHONY: lynx lynx-package
