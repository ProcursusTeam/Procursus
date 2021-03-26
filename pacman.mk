ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pacman
PACMAN_VERSION := 5.2.2
DEB_PACMAN_V   ?= $(PACMAN_VERSION)-3

pacman-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://git.archlinux.org/pacman.git/snapshot/pacman-$(PACMAN_VERSION).tar.gz
	$(call EXTRACT_TAR,pacman-$(PACMAN_VERSION).tar.gz,pacman-$(PACMAN_VERSION),pacman)
	$(call DO_PATCH,pacman,pacman,-p1)
	$(SED) -i -e "s/with_dri_platform = 'apple'/with_dri_platform = 'none'/" \
		-e "/dep_xcb_shm = dependency('xcb-shm')/a dep_xxf86vm = dependency('xxf86vm')" $(BUILD_WORK)/pacman/meson.build
	mkdir -p $(BUILD_WORK)/pacman/build

	echo -e "[host_machine]\n \
        system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/pacman/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/pacman/.build_complete),)
pacman:
	@echo "Using previously built pacman."
else
pacman: pacman-setup libarchive openssl curl gettext gpgme bash-completion
	cd $(BUILD_WORK)/pacman/build && PKG_CONFIG="pkg-config" meson \
                --cross-file cross.txt \
		--buildtype=plain \
		-Di18n=false \
		-Ddoc=disabled \
		-Dcrypto=openssl \
		..
	cd $(BUILD_WORK)/pacman/build; \
		DESTDIR="$(BUILD_STAGE)/pacman" meson install; \
		DESTDIR="$(BUILD_BASE)" meson install
	find $(BUILD_STAGE)/pacman -type f -exec $(SED) -i 's+/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/bin/+/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/+g' {} +
	touch $(BUILD_WORK)/pacman/.build_complete
endif

pacman-package: pacman-stage
	# pacman.mk Package Structure
	rm -rf $(BUILD_DIST)/pacman
	mkdir -p $(BUILD_DIST)/pacman

	# pacman.mk Prep pacman
	cp -a $(BUILD_STAGE)/pacman $(BUILD_DIST)

	# pacman.mk Sign
	$(call SIGN,pacman,general.xml)

	# pacman.mk Make .debs
	$(call PACK,pacman,DEB_PACMAN_V)

	# pacman.mk Build cleanup
	rm -rf $(BUILD_DIST)/pacman

.PHONY: pacman pacman-package
