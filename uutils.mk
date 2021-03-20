ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += uutils
UUTILS_VERSION   := 0.0.4
DEB_UUTILS_V     ?= $(COREUTILS_VERSION)-$(UUTILS_VERSION)

uutils-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/uutils-$(UUTILS_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/uutils-$(UUTILS_VERSION).tar.gz \
			https://github.com/uutils/coreutils/archive/$(UUTILS_VERSION).tar.gz
	$(call EXTRACT_TAR,uutils-$(UUTILS_VERSION).tar.gz,coreutils-$(UUTILS_VERSION),uutils)
	$(call DO_PATCH,uutils,uutils,-p1)
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/coreutils/coreutils-$(COREUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,coreutils-$(COREUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,coreutils-$(COREUTILS_VERSION).tar.xz,coreutils-$(COREUTILS_VERSION),uutils/coreutils)
	mkdir -p $(BUILD_WORK)/uutils/{su,rev,bsdcp}
	wget -q -nc -P $(BUILD_WORK)/uutils/su \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/su.c \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/suutil.{c,h} \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/su.1
	wget -q -nc -P $(BUILD_WORK)/uutils/rev \
		https://opensource.apple.com/source/text_cmds/text_cmds-88/rev/rev.{c,1}
	wget -q -nc -P $(BUILD_WORK)/uutils/bsdcp \
		https://opensource.apple.com/source/file_cmds/file_cmds-272.250.1/cp/{{cp,utils}.c,extern.h,cp.1} \
		https://opensource.apple.com/source/Libc/Libc-1353.41.1/gen/get_compat.h
	-[ ! -e "$(BUILD_SOURCE)/getent-darwin-$(GETENTDARWIN_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/getent-darwin-$(GETENTDARWIN_COMMIT).tar.gz \
			https://github.com/CRKatri/getent-darwin/archive/$(GETENTDARWIN_COMMIT).tar.gz
	$(call EXTRACT_TAR,getent-darwin-$(GETENTDARWIN_COMMIT).tar.gz,getent-darwin-$(GETENTDARWIN_COMMIT),uutils/getent-darwin)

ifneq ($(wildcard $(BUILD_WORK)/uutils/.build_complete),)
uutils:
	@echo "Using previously built uutils."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
uutils: uutils-setup gettext libxcrypt
else # (,$(findstring darwin,$(MEMO_TARGET)))
uutils: uutils-setup gettext
endif
	+SDKROOT="$(TARGET_SYSROOT)" $(MAKE) -C $(BUILD_WORK)/uutils TARGET=$(RUST_TARGET)
	$(MAKE) -C $(BUILD_WORK)/uutils install TARGET=$(RUST_TARGET) DESTDIR=$(BUILD_STAGE)/uutils PREFIX=/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) PROG_PREFIX=$(GNU_PREFIX)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/uutils/su && $(CC) $(CFLAGS) su.c suutil.c -o su -DBSD4_4 -D'__RCSID(x)=' $(LDFLAGS) -lcrypt
	cd $(BUILD_WORK)/uutils/rev && $(CC) $(CFLAGS) rev.c -o rev -D'__FBSDID(x)='
	cd $(BUILD_WORK)/uutils/bsdcp && $(CC) $(CFLAGS) -I. cp.c utils.c -o bsdcp -D'__FBSDID(x)='
	mv $(BUILD_WORK)/uutils/bsdcp/cp.1 $(BUILD_WORK)/uutils/bsdcp/bsdcp.1
endif
	cd $(BUILD_WORK)/uutils/coreutils && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--without-gmp \
		--enable-no-install-program="groups,hostname,kill,uptime,arch,base32,base64,basename,cat,chgrp,chmod,chown,chroot,cksum,comm,csplit,cut,dircolors,dirname,du,echo,env,expand,factor,false,fmt,fold,groups,head,hostid,hostname,id,kill,link,ln,logname,mkdir,mkfifo,mknod,mktemp,mv,nice,nl,nohup,nproc,paste,pathk,pinky,printenv,ptx,pwd,readlink,relpath,rm,rmdir,seq,shred,shuf,sleep,stdbuf,sum,sync,tac,tee,timeout,true,truncate,tsort,tty,uname,unexpand,uniq,unlink,uptime,users,wc,who,whoami,yes"
		$(COREUTILS_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/uutils/coreutils
	+$(MAKE) -C $(BUILD_WORK)/uutils/coreutils install \
		DESTDIR=$(BUILD_STAGE)/uutils
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	cp $(BUILD_WORK)/uutils/{su/su,rev/rev,bsdcp/bsdcp} $(BUILD_STAGE)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp $(BUILD_WORK)/uutils/{su/su,rev/rev,bsdcp/bsdcp}.1 $(BUILD_STAGE)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
endif
	+$(MAKE) -C $(BUILD_WORK)/uutils/getent-darwin install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/uutils/"
	touch $(BUILD_WORK)/uutils/.build_complete
endif

uutils-package: uutils-stage
	# uutils.mk Package Structure
	rm -rf $(BUILD_DIST)/uutils
	mkdir -p $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/{bin,$(MEMO_SUB_PREFIX)/sbin}
	
	# uutils.mk Prep uutils
	cp -a $(BUILD_STAGE)/uutils $(BUILD_DIST)
ifneq ($(MEMO_SUB_PREFIX),)
	ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chown $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/bin
	ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{cat,chgrp,cp,date,dd,dir,echo,false,kill,ln,ls,mkdir,mknod,mktemp,mv,pwd,readlink,rm,rmdir,sleep,stty,su,touch,true,uname,vdir} $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/etc/profile.d
	cp $(BUILD_INFO)/coreutils.sh $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/etc/profile.d
endif
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(echo $$bin | rev | cut -d/ -f1 | rev) $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $$bin | rev | cut -d/ -f1 | rev | cut -c2-); \
	done
endif
	
	# uutils.mk Sign
	$(call SIGN,uutils,general.xml)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(LDID) -S$(BUILD_INFO)/dd.xml $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cat # Do a manual sign for dd and cat.
	$(LDID) -S$(BUILD_INFO)/dd.xml $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cat
	find $(BUILD_DIST)/uutils -name '.ldid*' -type f -delete
endif
	
	# coreutils.mk Permissions
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$(GNU_PREFIX)su
endif
	
	# uutils.mk Make .debs
	$(call PACK,uutils,DEB_UUTILS_V)
	
	# uutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/uutils

.PHONY: uutils uutils-package
