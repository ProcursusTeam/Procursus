ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += subversion
SUBVERSION_VERSION := 1.14.1
DEB_SUBVERSION_V   ?= $(SUBVERSION_VERSION)-3

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
SUBVERSION_CONFIGURE_FLAGS :=
else
SUBVERSION_CONFIGURE_FLAGS := --disable-keychain
endif

subversion-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://archive.apache.org/dist/subversion/subversion-$(SUBVERSION_VERSION).tar.bz2
	$(call EXTRACT_TAR,subversion-$(SUBVERSION_VERSION).tar.bz2,subversion-$(SUBVERSION_VERSION),subversion)
	$(call DO_PATCH,subversion,subversion,-p1)

ifneq ($(wildcard $(BUILD_WORK)/subversion/.build_complete),)
subversion:
	@echo "Using previously built subversion."
else
subversion: subversion-setup apr apr-util expat file gettext libutf8proc libserf lz4
	cd $(BUILD_WORK)/subversion && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(SUBVERSION_CONFIGURE_FLAGS) \
		--enable-optimize \
		--disable-mod-activation \
		--disable-plaintext-password-storage \
		--with-apr=$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-apr-util=$(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-apxs=no \
		--with-libmagic=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-lz4=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-ruby-sitedir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/ruby/site_ruby \
		--with-serf=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-sqlite=$(TARGET_SYSROOT)/usr \
		--with-utf8proc=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-zlib=$(TARGET_SYSROOT)/usr \
		--without-apache-libexecdir \
		--without-berkeley-db \
		--without-boost \
		--without-gpg-agent \
		--without-jikes \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/apr-1.0" \
		ac_cv_func_memcmp_working=yes \
		ac_cv_lib_aprutil_1_apr_memcache_create=yes \
		svn_cv_atomic_builtins=yes
	# swig-py and swig-pl was terrible while cross compiling, not building
	+$(MAKE) -C $(BUILD_WORK)/subversion all tools \
		EXTRA_LDFLAGS="-Wl,-dead_strip_dylibs -no-undefined"
	+$(MAKE) -C $(BUILD_WORK)/subversion install install-tools \
		DESTDIR=$(BUILD_STAGE)/subversion
	+$(MAKE) -C $(BUILD_WORK)/subversion install \
		DESTDIR=$(BUILD_BASE)
	echo "Unversioned directory" > $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/subversion-1/svn-revision.txt
	mkdir -p $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions
	sed -i "1 s|^.*$$|#!/usr/bin/python3|" $(BUILD_WORK)/subversion/tools/server-side/svn-backup-dumps.py
	$(INSTALL) -m755 $(BUILD_WORK)/subversion/tools/server-side/svn-backup-dumps.py $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/svn-backup-dumps
	$(INSTALL) -m755 $(BUILD_WORK)/subversion/tools/backup/hot-backup.py $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/svn-hot-backup
	$(INSTALL) -m755 $(BUILD_WORK)/subversion/tools/client-side/svn-vendor.py $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/svn-vendor
	$(INSTALL) $(BUILD_WORK)/subversion/tools/client-side/bash_completion $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/svn
	for symlinks in svnadmin svndumpfilter svnlook svnsync svnversion; do $(LN_S) svn $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/$$symlinks; done
	$(call AFTER_BUILD)
endif

subversion-package: subversion-stage
	# subversion.mk Package Structure
	rm -rf $(BUILD_DIST)/subversion
	mkdir -p $(BUILD_DIST)/subversion{,-tools}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/bash-completion/completions}
	mkdir -p $(BUILD_DIST)/libsvn{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# subversion.mk Prep subversion
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/svn{,admin,bench,dumpfilter,fsfs,look,mucc,rdump,serve,sync,version} $(BUILD_DIST)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/svn-tools/svnauthz{,-validate} $(BUILD_DIST)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/svn{,admin,dumpfilter,look,sync,version} $(BUILD_DIST)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{locale,man} $(BUILD_DIST)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_MISC)/subversion/etc $(BUILD_DIST)/subversion/$(MEMO_PREFIX)

	# subversion.mk Prep subversion-tools
	cp -a $(BUILD_MISC)/subversion/bin/svn{wrap,-bisect,-clean,_apply_autoprops,_load_dirs} $(BUILD_DIST)/subversion-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/svn-{hot-backup,backup-dumps} $(BUILD_DIST)/subversion-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/svn-tools/{fsfs-{access-map,stats},svn{-mergeinfo-normalizer,-populate-node-origins-index,raisetreeconflict}} $(BUILD_DIST)/subversion-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_MISC)/subversion/man $(BUILD_DIST)/subversion-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# subversion.mk Prep libsvn1
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsvn_{client,delta,diff,fs{,_fs,_util,_x},ra{,_local,_serf,_svn},repos,subr,wc}-1{,.0}.dylib $(BUILD_DIST)/libsvn1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# subversion.mk Prep libsvn-dev
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsvn-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/subversion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/pkgconfig $(BUILD_DIST)/libsvn-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# subversion.mk Sign
	$(call SIGN,subversion,general.xml)
	$(call SIGN,subversion-tools,general.xml)
	$(call SIGN,libsvn1,general.xml)

	# subversion.mk Make .debs
	$(call PACK,subversion,DEB_SUBVERSION_V)
	$(call PACK,subversion-tools,DEB_SUBVERSION_V)
	$(call PACK,libsvn1,DEB_SUBVERSION_V)
	$(call PACK,libsvn-dev,DEB_SUBVERSION_V)

	# subversion.mk Build cleanup
	rm -rf $(BUILD_DIST)/{subversion{,-tools},libsvn{1,-dev}}

.PHONY: subversion subversion-package
