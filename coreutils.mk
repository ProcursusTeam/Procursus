ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += coreutils
COREUTILS_VERSION   := 8.32
GETENTDARWIN_COMMIT := 1ad0e39ee51181ea6c13b3d1d4e9c6005ee35b5e
DEB_COREUTILS_V     ?= $(COREUTILS_VERSION)-11

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
COREUTILS_CONFIGURE_ARGS += ac_cv_func_rpmatch=no
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
COREUTILS_CONFIGURE_ARGS += --program-prefix=$(GNU_PREFIX)
endif

coreutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/coreutils/coreutils-$(COREUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,coreutils-$(COREUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,coreutils-$(COREUTILS_VERSION).tar.xz,coreutils-$(COREUTILS_VERSION),coreutils)
	mkdir -p $(BUILD_WORK)/coreutils/{rev,bsdcp}
	wget -q -nc -P $(BUILD_WORK)/coreutils/rev \
		https://opensource.apple.com/source/text_cmds/text_cmds-88/rev/rev.{c,1}
	wget -q -nc -P $(BUILD_WORK)/coreutils/bsdcp \
		https://opensource.apple.com/source/file_cmds/file_cmds-272.250.1/cp/{{cp,utils}.c,extern.h,cp.1} \
		https://opensource.apple.com/source/Libc/Libc-1353.41.1/gen/get_compat.h
	wget -q -nc -P $(BUILD_SOURCE) \
		https://git.cameronkatri.com/getent-darwin/snapshot/getent-darwin-$(GETENTDARWIN_COMMIT).tar.zst
	$(call EXTRACT_TAR,getent-darwin-$(GETENTDARWIN_COMMIT).tar.zst,getent-darwin-$(GETENTDARWIN_COMMIT),coreutils/getent-darwin)

ifneq ($(wildcard $(BUILD_WORK)/coreutils/.build_complete),)
coreutils:
	@echo "Using previously built coreutils."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
coreutils: coreutils-setup gettext libgmp10 libxcrypt
else # (,$(findstring darwin,$(MEMO_TARGET)))
coreutils: coreutils-setup gettext libgmp10
endif # (,$(findstring darwin,$(MEMO_TARGET)))
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/coreutils/rev && $(CC) $(CFLAGS) rev.c -o rev -D'__FBSDID(x)='
	cd $(BUILD_WORK)/coreutils/bsdcp && $(CC) $(CFLAGS) -I. cp.c utils.c -o bsdcp -D'__FBSDID(x)='
	mv $(BUILD_WORK)/coreutils/bsdcp/cp.1 $(BUILD_WORK)/coreutils/bsdcp/bsdcp.1
endif
	cd $(BUILD_WORK)/coreutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(COREUTILS_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/coreutils
	+$(MAKE) -C $(BUILD_WORK)/coreutils install \
		DESTDIR=$(BUILD_STAGE)/coreutils
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	cp $(BUILD_WORK)/coreutils/{rev/rev,bsdcp/bsdcp} $(BUILD_STAGE)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp $(BUILD_WORK)/coreutils/{rev/rev,bsdcp/bsdcp}.1 $(BUILD_STAGE)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
endif
	+$(MAKE) -C $(BUILD_WORK)/coreutils/getent-darwin install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/coreutils/"
	touch $(BUILD_WORK)/coreutils/.build_complete
endif

coreutils-package: coreutils-stage
	# coreutils.mk Package Structure
	rm -rf $(BUILD_DIST)/coreutils
	mkdir -p $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/{bin,$(MEMO_SUB_PREFIX)/sbin}

	# coreutils.mk Prep coreutils
	cp -a $(BUILD_STAGE)/coreutils $(BUILD_DIST)
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chown $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chroot $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
ifneq ($(MEMO_SUB_PREFIX),)
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chown $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/bin
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{cat,chgrp,cp,date,dd,dir,echo,false,kill,ln,ls,mkdir,mknod,mktemp,mv,pwd,readlink,rm,rmdir,sleep,stty,touch,true,uname,vdir} $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/etc/profile.d
	cp $(BUILD_INFO)/coreutils.sh $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)/etc/profile.d
endif
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(echo $$bin | rev | cut -d/ -f1 | rev) $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $$bin | rev | cut -d/ -f1 | rev | cut -c2-); \
	done
endif

	# coreutils.mk Sign
	$(call SIGN,coreutils,general.xml)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(LDID) -S$(BUILD_INFO)/dd.xml $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dd # Do a manual sign for dd and cat.
	$(LDID) -S$(BUILD_INFO)/dd.xml $(BUILD_DIST)/coreutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cat
	find $(BUILD_DIST)/coreutils -name '.ldid*' -type f -delete
endif

	# coreutils.mk Make .debs
	$(call PACK,coreutils,DEB_COREUTILS_V)

	# coreutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/coreutils

.PHONY: coreutils coreutils-package
