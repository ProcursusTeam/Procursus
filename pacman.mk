ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pacman
PACMAN_VERSION := 5.2.2
DEB_PACMAN_V   ?= $(PACMAN_VERSION)-2

pacman-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://git.archlinux.org/pacman.git/snapshot/pacman-$(PACMAN_VERSION).tar.gz
	$(call EXTRACT_TAR,pacman-$(PACMAN_VERSION).tar.gz,pacman-$(PACMAN_VERSION),pacman)
	$(call DO_PATCH,pacman,pacman,-p1)

ifneq ($(wildcard $(BUILD_WORK)/pacman/.build_complete),)
pacman:
	@echo "Using previously built pacman."
else
pacman: pacman-setup libarchive openssl curl gettext
	cd $(BUILD_WORK)/pacman && ./autogen.sh
	cd $(BUILD_WORK)/pacman && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--disable-doc
	+$(MAKE) -C $(BUILD_WORK)/pacman
	+$(MAKE) -C $(BUILD_WORK)/pacman install \
		DESTDIR=$(BUILD_STAGE)/pacman
	find $(BUILD_STAGE)/pacman -type f -exec $(SED) -i 's+$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/bin/+$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/+g' {} +
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
