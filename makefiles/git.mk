ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += git
GIT_VERSION := 2.37.1
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
	XMLTO_EXTRA="--skip-validation"

git-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(GIT_VERSION).tar.xz)
	$(call EXTRACT_TAR,git-$(GIT_VERSION).tar.xz,git-$(GIT_VERSION),git)
	sed -i '/#include <CoreServices\/CoreServices.h>/a #include <FSEvents\/FSEvents.h>' $(BUILD_WORK)/git/compat/fsmonitor/fsm-listen-darwin.c
	sed -i 's/-framework CoreServices/-framework CoreServices -framework CoreFoundation/' $(BUILD_WORK)/git/config.mak.uname # On macOS, CoreServices reexports CoreFoundation, this doesn't happen on iOS

ifneq ($(wildcard $(BUILD_WORK)/git/.build_complete),)
git:
	@echo "Using previously built git."
else
git: git-setup openssl curl pcre2 gettext libidn2 expat
	+$(MAKE) -C "$(BUILD_WORK)/git" configure
	cd "$(BUILD_WORK)/git" && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libpcre2 \
		ac_cv_iconv_omits_bom=no \
		ac_cv_fread_reads_directories=no \
		ac_cv_snprintf_returns_bogus=yes \
		ac_cv_header_libintl_h=yes \
		NO_TCLTK=1 \
		CURL_CONFIG="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/curl-config"
	+$(MAKE) -C "$(BUILD_WORK)/git" all \
		$(GIT_ARGS)
	+$(MAKE) -C "$(BUILD_WORK)/git/Documentation" man install \
		$(GIT_ARGS)
	+$(MAKE) -C "$(BUILD_WORK)/git" install \
		$(GIT_ARGS)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	+$(MAKE) -C "$(BUILD_WORK)/git/contrib/credential/osxkeychain"
	cp -a "$(BUILD_WORK)/git/contrib/credential/osxkeychain/git-credential-osxkeychain" "$(BUILD_STAGE)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/git-credential-osxkeychain"
	mkdir "$(BUILD_STAGE)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc"
	cp -a "$(BUILD_MISC)/git/gitconfig.macosx" "$(BUILD_STAGE)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc/gitconfig"
endif
	$(call AFTER_BUILD)
endif

git-package: git-stage
	# git.mk Package Structure
	rm -rf "$(BUILD_DIST)/git"
	mkdir -p "$(BUILD_DIST)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"/{bin,share,libexec}
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p "$(BUILD_DIST)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc"
endif

	# git.mk Prep git
	cp -a "$(BUILD_STAGE)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"/{bin,share,libexec} "$(BUILD_DIST)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	cp -a "$(BUILD_STAGE)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc" "$(BUILD_DIST)/git/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
endif

	# git.mk Sign
	$(call SIGN,git,general.xml)

	# git.mk Make .debs
	$(call PACK,git,DEB_GIT_V)

	# git.mk Build cleanup
	rm -rf "$(BUILD_DIST)/git"

.PHONY: git git-package
