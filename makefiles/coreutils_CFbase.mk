ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

COREUTILS_CFBASE_VERSION   	:= 9.1
GETENTDARWIN_CFBASE_COMMIT := 1ad0e39ee51181ea6c13b3d1d4e9c6005ee35b5e

COREUTILS_CFBASE_CONFIGURE_ARGS += ac_cv_func_rpmatch=no

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
COREUTILS_CFBASE_CONFIGURE_ARGS += --program-prefix=$(GNU_PREFIX)
endif

coreutils_CFbase-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/coreutils/coreutils-$(COREUTILS_CFBASE_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,coreutils-$(COREUTILS_CFBASE_VERSION).tar.xz)
	$(call EXTRACT_TAR,coreutils-$(COREUTILS_CFBASE_VERSION).tar.xz,coreutils-$(COREUTILS_CFBASE_VERSION),coreutils)
	touch $(BUILD_WORK)/coreutils/reflink-apfs.patch.done
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE), \
		https://git.cameronkatri.com/getent-darwin/snapshot/getent-darwin-$(GETENTDARWIN_CFBASE_COMMIT).tar.zst)
	$(call EXTRACT_TAR,getent-darwin-$(GETENTDARWIN_CFBASE_COMMIT).tar.zst,getent-darwin-$(GETENTDARWIN_CFBASE_COMMIT),coreutils/getent-darwin)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's#__FBSDID#//__FBSDID#g' $(BUILD_WORK)/coreutils/getent-darwin/getent.c
	sed -i 's#__FBSDID#//__FBSDID#g' $(BUILD_WORK)/coreutils/getent-darwin/getutxent.c
endif


ifneq ($(wildcard $(BUILD_WORK)/coreutils/.build_complete),)
coreutils_CFbase:
	@echo "Using previously built coreutils."
else
ifneq (,$(findstring ramdisk,$(MEMO_TARGET)))
coreutils_CFbase: coreutils-setup
else ifeq (,$(findstring darwin,$(MEMO_TARGET)))
coreutils_CFbase: coreutils-setup gettext libgmp10 libxcrypt openssl
else # (,$(findstring darwin,$(MEMO_TARGET)))
coreutils_CFbase: coreutils-setup gettext libgmp10 openssl
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/coreutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) LDFLAGS="-L /usr/lib/gcc/arm-apple-darwin9/4.0.1/v6/ -lgcc" \
		$(COREUTILS_CFBASE_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/coreutils
	+$(MAKE) -C $(BUILD_WORK)/coreutils install \
		DESTDIR=$(BUILD_STAGE)/coreutils
	+$(MAKE) -C $(BUILD_WORK)/coreutils/getent-darwin install \
		CFLAGS="$(CFLAGS) -D__NO_TLS=1 $(LDFLAGS)" \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/coreutils/"
	$(call AFTER_BUILD)
endif

coreutils_CFbase-package:: DEB_COREUTILS_V ?= $(COREUTILS_CFBASE_VERSION)
coreutils_CFbase-package: coreutils-stage
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

.PHONY: coreutils_CFbase coreutils_CFbase-package