ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += cgit
CGIT_VERSION     := 1.2.3
CGIT_GIT_VERSION := 2.25.1
DEB_CGIT_V       ?= $(CGIT_VERSION)

CGIT_ARGS += uname_S=Darwin \
	HOST_CPU=$(GNU_HOST_TRIPLE) \
	DESTDIR=$(BUILD_STAGE)/cgit \
	prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	CGIT_SCRIPT_PATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/cgit \
	NO_GETTEXT=1 \
	NO_LUA=1 \
	NO_R_TO_GCC_LINKER=1 \
	NO_DARWIN_PORTS=1 \
	NO_FINK=1 \
	NO_APPLE_COMMON_CRYPTO=1 \
	INSTALL_SYMLINKS=1 \
	NO_INSTALL_HARDLINKS=1 \
	V=1 \
	CC=$(CC) \
	AR=$(AR) \
	CFLAGS="$(CFLAGS)" \
	LDFLAGS="$(LDFLAGS)"

cgit-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://git.zx2c4.com/cgit/snapshot/cgit-$(CGIT_VERSION).tar.xz
	wget -q -nc -P $(BUILD_SOURCE) https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(CGIT_GIT_VERSION).tar.xz
	$(call EXTRACT_TAR,cgit-$(CGIT_VERSION).tar.xz,cgit-$(CGIT_VERSION),cgit)
	rm -rf $(BUILD_WORK)/cgit/git
	$(call EXTRACT_TAR,git-$(CGIT_GIT_VERSION).tar.xz,git-$(CGIT_GIT_VERSION),cgit/git)
	-wget -q -nc -O$(BUILD_WORK)/cgit/memrchr.c https://cgit.freebsd.org/src/plain/lib/libc/string/memrchr.c?h=stable/13
	$(call DO_PATCH,cgit,cgit,-p1)
	$(SED) -i '\|-I/usr/local/include|d' $(BUILD_WORK)/cgit/git/config.mak.uname
	$(SED) -i '\|-L/usr/local/lib|d' $(BUILD_WORK)/cgit/git/config.mak.uname

ifneq ($(wildcard $(BUILD_WORK)/cgit/.build_complete),)
cgit:
	@echo "Using previously built cgit."
else
cgit: cgit-setup openssl
	+$(MAKE) -C $(BUILD_WORK)/cgit all \
		$(CGIT_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/cgit install \
		$(CGIT_ARGS)
	mv $(BUILD_STAGE)/cgit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/cgit/cgit.cgi \
		$(BUILD_STAGE)/cgit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cgit
	touch $(BUILD_WORK)/cgit/.build_complete
endif

cgit-package: cgit-stage
	# cgit.mk Package Structure
	rm -rf $(BUILD_DIST)/cgit
	
	# cgit.mk Prep cgit
	cp -a $(BUILD_STAGE)/cgit $(BUILD_DIST)/cgit
	
	# cgit.mk Sign
	$(call SIGN,cgit,general.xml)
	
	# cgit.mk Make .debs
	$(call PACK,cgit,DEB_CGIT_V)
	
	# cgit.mk Build cleanup
	rm -rf $(BUILD_DIST)/cgit

.PHONY: cgit cgit-package
