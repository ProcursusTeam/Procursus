ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += coreutils
COREUTILS_VERSION   := 9.4
GETENTDARWIN_COMMIT := 1ad0e39ee51181ea6c13b3d1d4e9c6005ee35b5e
DEB_COREUTILS_V     ?= $(COREUTILS_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
COREUTILS_CONFIGURE_ARGS += ac_cv_func_rpmatch=no
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
COREUTILS_CONFIGURE_ARGS += --program-prefix=$(GNU_PREFIX)
endif

coreutils-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftp.gnu.org/gnu/coreutils/coreutils-$(COREUTILS_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,coreutils-$(COREUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,coreutils-$(COREUTILS_VERSION).tar.xz,coreutils-$(COREUTILS_VERSION),coreutils)
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE), \
		https://git.cameronkatri.com/getent-darwin/snapshot/getent-darwin-$(GETENTDARWIN_COMMIT).tar.zst)
	$(call EXTRACT_TAR,getent-darwin-$(GETENTDARWIN_COMMIT).tar.zst,getent-darwin-$(GETENTDARWIN_COMMIT),coreutils/getent-darwin)

ifneq ($(wildcard $(BUILD_WORK)/coreutils/.build_complete),)
coreutils:
	@echo "Using previously built coreutils."
else
ifneq (,$(findstring ramdisk,$(MEMO_TARGET)))
coreutils: coreutils-setup
else ifeq (,$(findstring darwin,$(MEMO_TARGET)))
coreutils: coreutils-setup gettext libgmp10 libxcrypt openssl
else # (,$(findstring darwin,$(MEMO_TARGET)))
coreutils: coreutils-setup gettext libgmp10 openssl
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/coreutils && autoreconf -fi
	cd $(BUILD_WORK)/coreutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(COREUTILS_CONFIGURE_ARGS) \
		gl_cv_macro_MB_CUR_MAX_good=yes
	+$(MAKE) -C $(BUILD_WORK)/coreutils
	+$(MAKE) -C $(BUILD_WORK)/coreutils install \
		DESTDIR=$(BUILD_STAGE)/coreutils
	+$(MAKE) -C $(BUILD_WORK)/coreutils/getent-darwin install \
		CFLAGS="$(CFLAGS) $(LDFLAGS)" \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/coreutils/"
	$(call AFTER_BUILD)
endif

coreutils-package: coreutils-stage
	# coreutils.mk Package Structure
	rm -rf $(BUILD_DIST)/coreutils
	mkdir -p $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/{bin,$(MEMO_SUB_PREFIX)/sbin}

	# coreutils.mk Prep coreutils
	cp -a $(BUILD_STAGE)/coreutils $(BUILD_DIST)
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$(GNU_PREFIX)chown $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$(GNU_PREFIX)chroot $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
ifneq ($(MEMO_SUB_PREFIX),)
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chown $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/bin
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{cat,chgrp,cp,date,dd,dir,echo,false,kill,ln,ls,mkdir,mknod,mktemp,mv,pwd,readlink,rm,rmdir,sleep,stty,touch,true,uname,vdir} $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/etc/profile.d
	cp $(BUILD_INFO)/coreutils.sh $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/etc/profile.d
endif
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin##*/} $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $${bin##*/} | cut -c2-); \
	done
endif

	# coreutils.mk Sign
	$(call SIGN,coreutils,general.xml)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(LDID) -S$(BUILD_MISC)/entitlements/dd.xml $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dd # Do a manual sign for dd and cat.
	$(LDID) -S$(BUILD_MISC)/entitlements/dd.xml $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cat
	find $(BUILD_DIST)/coreutils -name '.ldid*' -type f -delete
endif

	# coreutils.mk Make .debs
	$(call PACK,coreutils,DEB_COREUTILS_V)

	# coreutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/coreutils

.PHONY: coreutils coreutils-package
