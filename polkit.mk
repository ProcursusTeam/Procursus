ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += polkit
POLKIT_VERSION := 0.118
DEB_POLKIT_V   ?= $(POLKIT_VERSION)

polkit-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.freedesktop.org/software/polkit/releases/polkit-0.118.tar.gz
	$(call EXTRACT_TAR,polkit-$(POLKIT_VERSION).tar.gz,polkit-$(POLKIT_VERSION),polkit)
	$(call DO_PATCH,polkit,polkit,-p1)

ifneq ($(wildcard $(BUILD_WORK)/polkit/.build_complete),)
polkit:
	@echo "Using previously built polkit."
else
polkit: polkit-setup libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/polkit && autoreconf -fiv && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-duktape \
		--enable-libelogind=no \
		--enable-introspection=no \
		--enable-libsystemd-login=no \
		--disable-test
	find $(BUILD_WORK)/polkit -type f -exec sed -i 's/-Wl,--as-needed/-Wl/g' {} \;
	+$(MAKE) -C $(BUILD_WORK)/polkit
	+$(MAKE) -C $(BUILD_WORK)/polkit install \
		DESTDIR=$(BUILD_STAGE)/polkit
	+$(MAKE) -C $(BUILD_WORK)/polkit install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/polkit/.build_complete
endif

polkit-package: polkit-stage
	# polkit.mk Package Structure
	rm -rf $(BUILD_DIST)/polkit

	# polkit.mk Prep polkit
	cp -a $(BUILD_STAGE)/polkit $(BUILD_DIST)

	# polkit.mk Sign
	$(call SIGN,polkit,general.xml)

	# polkit.mk Make .debs
	$(call PACK,polkit,DEB_POLKIT_V)

	# polkit.mk Build cleanup
	rm -rf $(BUILD_DIST)/polkit

.PHONY: polkit polkit-package
