ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += fakeroot
FAKEROOT_VERSION   := 1.31
DEB_FAKEROOT_V     ?= $(FAKEROOT_VERSION)-1

### mknodat introduced in iOS 16

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1900 ] && echo 1),1)
FAKEROOT_CONFIGURE_FLAGS := ac_cv_func_mknodat=no
endif

fakeroot-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://deb.debian.org/debian/pool/main/f/fakeroot/fakeroot_$(FAKEROOT_VERSION).orig.tar.gz)
	$(call EXTRACT_TAR,fakeroot_$(FAKEROOT_VERSION).orig.tar.gz,fakeroot-$(FAKEROOT_VERSION),fakeroot)
	$(call DO_PATCH,fakeroot,fakeroot,-p1)
	sed -i 's/SOL_TCP/IPPROTO_TCP/g' $(BUILD_WORK)/fakeroot/communicate.c

ifneq ($(wildcard $(BUILD_WORK)/fakeroot/.build_complete),)
fakeroot:
	@echo "Using previously built fakeroot."
else
fakeroot: fakeroot-setup
	cd $(BUILD_WORK)/fakeroot && autoreconf -vi
	cd $(BUILD_WORK)/fakeroot && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(FAKEROOT_CONFIGURE_FLAGS) \
		--with-ipc=tcp \
		CFLAGS="$(CFLAGS) -DLIBIOSEXEC_INTERNAL=1" \
		CPPFLAGS="$(CPPFLAGS) -DLIBIOSEXEC_INTERNAL=1"
	sed -i 's|@SHELL@|$(MEMO_PREFIX)/bin/sh|' $(BUILD_WORK)/fakeroot/scripts/fakeroot.in
	+$(MAKE) -C $(BUILD_WORK)/fakeroot all \
		CFLAGS='$(CFLAGS) -D__DARWIN_UNIX03 -DMAC_OS_X_VERSION_MIN_REQUIRED=1000'
	+$(MAKE) -C $(BUILD_WORK)/fakeroot install \
		DESTDIR=$(BUILD_STAGE)/fakeroot
	$(call AFTER_BUILD)
endif

fakeroot-package: fakeroot-stage
	# fakeroot.mk Package Structure
	rm -rf $(BUILD_DIST)/fakeroot

	# fakeroot.mk Prep fakeroot
	cp -a $(BUILD_STAGE)/fakeroot $(BUILD_DIST)

	# fakeroot.mk Sign
	$(call SIGN,fakeroot,general.xml)

	# fakeroot.mk Make .debs
	$(call PACK,fakeroot,DEB_FAKEROOT_V)

	# fakeroot.mk Build cleanup
	rm -rf $(BUILD_DIST)/fakeroot

.PHONY: fakeroot fakeroot-package
