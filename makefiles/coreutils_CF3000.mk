ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

COREUTILS_CF3000_VERSION   := 9.5
GETENTDARWIN_CF3000_COMMIT  := 1ad0e39ee51181ea6c13b3d1d4e9c6005ee35b5e

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
COREUTILS_CF3000_CONFIGURE_ARGS += --program-prefix=$(GNU_PREFIX)
endif

coreutils_CF3000-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftp.gnu.org/gnu/coreutils/coreutils-$(COREUTILS_CF3000_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,coreutils-$(COREUTILS_CF3000_VERSION).tar.xz)
	$(call EXTRACT_TAR,coreutils-$(COREUTILS_CF3000_VERSION).tar.xz,coreutils-$(COREUTILS_CF3000_VERSION),coreutils)
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE), \
		https://git.cameronkatri.com/getent-darwin/snapshot/getent-darwin-$(GETENTDARWIN_CF3000_COMMIT).tar.zst)
	$(call GIT_CLONE_COMMIT,https://git.cameronkatri.com/getent-darwin.git,$(GETENTDARWIN_CF3000_COMMIT),coreutils/getent-darwin)

ifneq ($(wildcard $(BUILD_WORK)/coreutils/.build_complete),)
coreutils_CF3000:
	@echo "Using previously built coreutils."
else
ifneq (,$(findstring ramdisk,$(MEMO_TARGET)))
coreutils_CF3000: coreutils-setup
else ifeq (,$(findstring darwin,$(MEMO_TARGET)))
coreutils_CF3000: coreutils-setup gettext libgmp10 libxcrypt openssl
else # (,$(findstring darwin,$(MEMO_TARGET)))
coreutils_CF3000: coreutils-setup gettext libgmp10 openssl
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/coreutils && autoreconf -fi
	cd $(BUILD_WORK)/coreutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(COREUTILS_CONFIGURE_ARGS) \
		gl_cv_macro_MB_CUR_MAX_good=yes
	+$(MAKE) -C $(BUILD_WORK)/coreutils \
		CFLAGS="$(CFLAGS) -D_GL_ATTRIBUTE_MAYBE_UNUSED= "
	+$(MAKE) -C $(BUILD_WORK)/coreutils install \
		DESTDIR=$(BUILD_STAGE)/coreutils
	+$(MAKE) -C $(BUILD_WORK)/coreutils/getent-darwin install \
		CFLAGS="$(CFLAGS) $(LDFLAGS)" \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/coreutils/"
	$(call AFTER_BUILD)
endif

coreutils_CF3000-package:: DEB_COREUTILS_V ?= $(COREUTILS_CF3000_VERSION)
coreutils_CF3000-package: coreutils-stage
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

	# coreutils.mk Make .debs
	$(call PACK,coreutils,DEB_COREUTILS_V)

	# coreutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/coreutils

.PHONY: coreutils_CF3000 coreutils_CF3000-package