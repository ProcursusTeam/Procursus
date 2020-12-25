ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS     += coreutils
COREUTILS_VERSION := 8.32
DEB_COREUTILS_V   ?= $(COREUTILS_VERSION)-7

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
COREUTILS_CONFIGURE_ARGS += ac_cv_func_rpmatch=no
endif

coreutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/coreutils/coreutils-$(COREUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,coreutils-$(COREUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,coreutils-$(COREUTILS_VERSION).tar.xz,coreutils-$(COREUTILS_VERSION),coreutils)
	mkdir -p $(BUILD_WORK)/coreutils/{su,rev,bsdcp}
	wget -q -nc -P $(BUILD_WORK)/coreutils/su \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/su.c \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/suutil.{c,h} \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/su.1
	wget -q -nc -P $(BUILD_WORK)/coreutils/rev \
		https://opensource.apple.com/source/text_cmds/text_cmds-88/rev/rev.{c,1}
	wget -q -nc -P $(BUILD_WORK)/coreutils/bsdcp \
		https://opensource.apple.com/source/file_cmds/file_cmds-272.250.1/cp/{{cp,utils}.c,extern.h,cp.1} \
		https://opensource.apple.com/source/Libc/Libc-1353.41.1/gen/get_compat.h

ifneq ($(wildcard $(BUILD_WORK)/coreutils/.build_complete),)
coreutils:
	@echo "Using previously built coreutils."
else
coreutils: coreutils-setup gettext libxcrypt
	cd $(BUILD_WORK)/coreutils/su && $(CC) $(CFLAGS) su.c suutil.c -o su -DBSD4_4 -D'__RCSID(x)=' $(LDFLAGS) -lcrypt
	cd $(BUILD_WORK)/coreutils/rev && $(CC) $(CFLAGS) rev.c -o rev -D'__FBSDID(x)='
	cd $(BUILD_WORK)/coreutils/bsdcp && $(CC) $(CFLAGS) -I. cp.c utils.c -o bsdcp -D'__FBSDID(x)='
	mv $(BUILD_WORK)/coreutils/bsdcp/cp.1 $(BUILD_WORK)/coreutils/bsdcp/bsdcp.1
	cd $(BUILD_WORK)/coreutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-gmp \
		$(COREUTILS_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/coreutils
	+$(MAKE) -C $(BUILD_WORK)/coreutils install \
		DESTDIR=$(BUILD_STAGE)/coreutils
	cp $(BUILD_WORK)/coreutils/{su/su,rev/rev,bsdcp/bsdcp} $(BUILD_STAGE)/coreutils/usr/bin
	cp $(BUILD_WORK)/coreutils/{su/su,rev/rev,bsdcp/bsdcp}.1 $(BUILD_STAGE)/coreutils/usr/share/man/man1
	touch $(BUILD_WORK)/coreutils/.build_complete
endif

coreutils-package: coreutils-stage
	# coreutils.mk Package Structure
	rm -rf $(BUILD_DIST)/coreutils
	mkdir -p $(BUILD_DIST)/coreutils/{etc/profile.d,bin,usr/sbin}
	
	# coreutils.mk Prep coreutils
	cp -a $(BUILD_STAGE)/coreutils/usr $(BUILD_DIST)/coreutils
	ln -s /usr/bin/chown $(BUILD_DIST)/coreutils/usr/sbin
	ln -s /usr/bin/chown $(BUILD_DIST)/coreutils/bin
	ln -s /usr/bin/chroot $(BUILD_DIST)/coreutils/usr/sbin
	ln -s /usr/bin/{cat,chgrp,cp,date,dd,dir,echo,false,kill,ln,ls,mkdir,mknod,mktemp,mv,pwd,readlink,rm,rmdir,sleep,stty,su,touch,true,uname,vdir} $(BUILD_DIST)/coreutils/bin
	cp $(BUILD_INFO)/coreutils.sh $(BUILD_DIST)/coreutils/etc/profile.d

	# coreutils.mk Sign
	$(call SIGN,coreutils,general.xml)
	$(LDID) -S$(BUILD_INFO)/dd.xml $(BUILD_DIST)/coreutils/usr/bin/dd # Do a manual sign for dd and cat.
	$(LDID) -S$(BUILD_INFO)/dd.xml $(BUILD_DIST)/coreutils/usr/bin/cat
	find $(BUILD_DIST)/coreutils -name '.ldid*' -type f -delete

	# coreutils.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/coreutils/usr/bin/su
	
	# coreutils.mk Make .debs
	$(call PACK,coreutils,DEB_COREUTILS_V)
	
	# coreutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/coreutils

.PHONY: coreutils coreutils-package
