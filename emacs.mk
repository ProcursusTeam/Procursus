ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += emacs
EMACS_VERSION := 27.1
DEB_EMACS_V   ?= $(EMACS_VERSION)

emacs-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://ftp.gnu.org/gnu/emacs/emacs-27.1.tar.xz
	$(call EXTRACT_TAR,emacs-$(EMACS_VERSION).tar.xz,emacs-$(EMACS_VERSION),emacs)
	$(call DO_PATCH,emacs,emacs,-p1)

ifneq ($(wildcard $(BUILD_WORK)/emacs/.build_complete),)
emacs:
	@echo "Using previously built emacs."
else
emacs: emacs-setup libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/emacs && autoreconf -vfi && mkdir -p "native-build" && pushd "native-build" && unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS PKG_CONFIG_PATH PKG_CONFIG_LIBDIR ACLOCAL_PATH && ../configure \
	--with-modules \
	--without-x \
	--without-ns \
	--without-dbus
	+$(MAKE) -C $(BUILD_WORK)/emacs/native-build
	cd $(BUILD_WORK)/emacs && export gl_cv_func_getgroups_works=yes && \
	export gl_cv_func_gettimeofday_clobber=no && \
	export ac_cv_func_getgroups_works=yes && \
	export ac_cv_func_mmap_fixed_mapped=yes && \
	export gl_cv_func_working_utimes=yes && \
	export gl_cv_func_open_slash=no && \
	export fu_cv_sys_stat_statfs2_bsize=yes && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-modules \
		--without-dbus \
		--x-libraries=$(BUILD_BASE)/usr/lib \
		--x-includes=$(BUILD_BASE)/usr/include \
		--without-ns \
		--with-pdumper=yes \
		--with-unexec=no \
		--with-dumping=none \
		--without-makeinfo
	+$(MAKE) -C $(BUILD_WORK)/emacs
	+$(MAKE) -C $(BUILD_WORK)/emacs install \
		DESTDIR=$(BUILD_STAGE)/emacs
	+$(MAKE) -C $(BUILD_WORK)/emacs install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/emacs/.build_complete
endif

emacs-package: emacs-stage
	# emacs.mk Package Structure
	rm -rf $(BUILD_DIST)/emacs

	# emacs.mk Prep emacs
	cp -a $(BUILD_STAGE)/emacs $(BUILD_DIST)

	# emacs.mk Sign
	$(call SIGN,emacs,general.xml)

	# emacs.mk Make .debs
	$(call PACK,emacs,DEB_EMACS_V)

	# emacs.mk Build cleanup
	rm -rf $(BUILD_DIST)/emacs

.PHONY: emacs emacs-package
