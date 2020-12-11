ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pacman
PACMAN_VERSION := 5.2.2
DEB_PACMAN_V   ?= $(PACMAN_VERSION)-3

pacman-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://sources.archlinux.org/other/pacman/pacman-$(PACMAN_VERSION).tar.gz
	$(call EXTRACT_TAR,pacman-$(PACMAN_VERSION).tar.gz,pacman-$(PACMAN_VERSION),pacman)
	$(call DO_PATCH,pacman,pacman,-p1)

ifneq ($(wildcard $(BUILD_WORK)/pacman/.build_complete),)
pacman:
	@echo "Using previously built pacman."
else
pacman: pacman-setup libarchive openssl curl gettext libassuan libgpg-error gpgme
	cd $(BUILD_WORK)/pacman && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--disable-dependency-tracking \
		--with-scriptlet-shell="/bin/bash"
	+$(MAKE) -C $(BUILD_WORK)/pacman
	+$(MAKE) -C $(BUILD_WORK)/pacman install \
		DESTDIR=$(BUILD_STAGE)/pacman
	touch $(BUILD_WORK)/pacman/.build_complete
endif

pacman-package: pacman-stage
	# pacman.mk Package Structure
	rm -rf $(BUILD_DIST)/pacman \
		$(BUILD_DIST)/libalpm{12,-dev}
	mkdir -p $(BUILD_DIST)/pacman/usr/ \
		$(BUILD_DIST)/libalpm12/usr/{lib,share/man/man5} \
		$(BUILD_DIST)/libalpm-dev/usr/lib
	
	# pacman.mk Prep pacman
	cp -a $(BUILD_STAGE)/pacman/etc $(BUILD_DIST)/pacman
	cp -a $(BUILD_STAGE)/pacman/usr/{bin,share} $(BUILD_DIST)/pacman/usr
	rm -rf $(BUILD_DIST)/pacman/usr/share/libalpm
	rm -rf $(BUILD_DIST)/pacman/usr/share/man/{man3,man5/alpm-hooks.5}
	
	# pacman.mk Prep libalpm12
	cp -a $(BUILD_STAGE)/pacman/usr/lib/libalpm.12.dylib $(BUILD_DIST)/libalpm12/usr/lib
	cp -a $(BUILD_STAGE)/pacman/usr/share/man/man3 $(BUILD_DIST)/libalpm12/usr/share/man
	cp -a $(BUILD_STAGE)/pacman/usr/share/man/man5/alpm-hooks.5 $(BUILD_DIST)/libalpm12/usr/share/man/man5
	cp -a $(BUILD_STAGE)/pacman/usr/share/libalpm $(BUILD_DIST)/libalpm12/usr/share
	cp -a $(BUILD_STAGE)/pacman/usr/var $(BUILD_DIST)/libalpm12/usr/
	
	# pacman.mk Prep libalpm-dev
	cp -a $(BUILD_STAGE)/pacman/usr/lib/{pkgconfig,libalpm.{dylib,a}} $(BUILD_DIST)/libalpm-dev/usr/lib
	cp -a $(BUILD_STAGE)/pacman/usr/include $(BUILD_DIST)/libalpm-dev/usr
	
	# pacman.mk Sign
	$(call SIGN,pacman,general.xml)
	$(call SIGN,libalpm12,general.xml)
	
	# pacman.mk Make .debs
	$(call PACK,pacman,DEB_PACMAN_V)
	$(call PACK,libalpm12,DEB_PACMAN_V)
	$(call PACK,libalpm-dev,DEB_PACMAN_V)
	
	# pacman.mk Build cleanup
	rm -rf $(BUILD_DIST)/pacman \
		$(BUILD_DIST)/libalpm{12,-dev}

.PHONY: pacman pacman-package
