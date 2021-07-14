ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += git
GIT_VERSION := 2.32.0
DEB_GIT_V   ?= $(GIT_VERSION)

GIT_ARGS += uname_S=Darwin \
	HOST_CPU=$(GNU_HOST_TRIPLE) \
	DESTDIR=$(BUILD_STAGE)/git \
	MANDIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
	PYTHON_PATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3 \
	NO_DARWIN_PORTS=1 \
	NO_FINK=1 \
	NO_APPLE_COMMON_CRYPTO=1 \
	INSTALL_SYMLINKS=1 \
	NO_INSTALL_HARDLINKS=1 \
	V=1

git-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(GIT_VERSION).tar.xz
	$(call EXTRACT_TAR,git-$(GIT_VERSION).tar.xz,git-$(GIT_VERSION),git)

ifneq ($(wildcard $(BUILD_WORK)/git/.build_complete),)
git:
	@echo "Using previously built git."
else
git: git-setup openssl curl pcre2 gettext libidn2 expat
	+$(MAKE) -C $(BUILD_WORK)/git configure
	cd $(BUILD_WORK)/git && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libpcre2 \
		ac_cv_iconv_omits_bom=no \
		ac_cv_fread_reads_directories=no \
		ac_cv_snprintf_returns_bogus=yes \
		ac_cv_header_libintl_h=yes \
		NO_TCLTK=1 \
		CURL_CONFIG=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/curl-config
	+$(MAKE) -C $(BUILD_WORK)/git all \
		$(GIT_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/git/Documentation man install \
		$(GIT_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/git install \
		$(GIT_ARGS)
	touch $(BUILD_WORK)/git/.build_complete
endif

git-package: git-stage
	# git.mk Package Structure
	rm -rf $(BUILD_DIST)/git
	mkdir -p $(BUILD_DIST)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share,libexec}

	# git.mk Prep git
	cp -a $(BUILD_STAGE)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share,libexec} $(BUILD_DIST)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# git.mk Sign
	$(call SIGN,git,general.xml)

	# git.mk Make .debs
	$(call PACK,git,DEB_GIT_V)

	# git.mk Build cleanup
	rm -rf $(BUILD_DIST)/git

.PHONY: git git-package
