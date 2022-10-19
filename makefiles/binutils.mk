ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += binutils
BINUTILS_VERSION := 2.39
DEB_BINUTILS_V   ?= $(BINUTILS_VERSION)

BINUTILS_TARGETS := x86_64-linux-gnu aarch64-linux-gnu aarch64-apple-darwin # x86_64-apple-darwin aarch64-apple-darwin # aarch64-linux-musl aarch64-linux-gnu_ilp32 aarch64-linux-musl_ilp32 alpha-linux-gnu alpha-linux-musl arm-linux-gnueabi arm-linux-gnueabihf arm-linux-musleabi arm-linux-musleabihf hppa-linux-gnu hppa64-linux-gnu hppa-linux-musl hppa64-linux-musl loongarch64-elf loongarch64-linux-gnu loongarch64-linux-musl i686-kfreebsd-gnu i486-linux-gnu i486-linux-musl ia64-linux-gnu ia64-linux-musl m68k-linux-gnu m68k-linux-musl mips64el-linux-gnuabi64 mips64el-linux-musl mipsel-linux-gnu mipsel-linux-musl powerpc-linux-gnu powerpc-linux-musl powerpc64-linux-gnu powerpc64-linux-musl powerpc64le-linux-gnu powerpc64le-linux-musl riscv64-linux-gnu riscv64-linux-musl riscv32-linux-gnu riscv32-linux-musl s390x-linux-gnu s390x-linux-musl sh4-linux-gnu sh4-linux-musl sparc64-linux-gnu sparc64-linux-musl x86_64-linux-gnu x86_64-linux-musl x86_64-linux-gnux32 x86_64-linux-muslx32 powerpc-apple-darwin x86_64-apple-darwin i686-apple-darwin arm-apple-darwin aarch64-apple-darwin i686-hurd-gnu i686-elf z80-elf x86_64-elf arm-none-eabi aarch64-elf riscv64-elf riscv32-elf ia64-elf m68k-elf powerpc-elf powerpc64-elf powerpc64le-elf mips64el-elf hppa64-elf hppa-elf sh4-elf sparc64-elf powerpc64-freebsd powerpc64le-freebsd x86_64-freebsd i386-freebsd arm-freebsd aarch64-freebsd alpha-netbsd x86_64-netbsd mips-netbsd powerpc-netbsd sparc-netbsd sparc64-netbsd ia64-netbsd x86_64-dragonfly x86_64-sun-solaris sparc-sun-solaris sparc64-sun-solaris alpha-dec-osf hppa64-hp-hpux hppa-hp-hpux i486-beos i486-bsdi i586-pc-cygwin powerpc-ibm-aix rs6000-ibm-aix sparc-unknown-bsdi i586-w64-mingw32 x86_64-w64-mingw32 x86_64-openbsd i386-openbsd alpha-openbsd hppa-openbsd hppa64-openbsd powerpc-openbsd powerpc64-openbsd sparc64-openbsd mips64el-openbsd sparc-openbsd riscv64-openbsd i686-haiku x86_64-haiku riscv64-haiku sparc-haiku arm-haiku aarch64-haiku powerpc-haiku

BINUTILS_CONFARGS := --enable-obsolete \
	--enable-shared \
	--enable-plugins \
	--enable-threads \
	--with-system-zlib \
	--enable-deterministic-archives \
	--disable-compressed-debug-sections \
	--enable-new-dtags \
	--disable-x86-used-note \
	--with-pkgversion="GNU Binutils for Procursus" \
	--enable-ld=default \
	--enable-gold \
	--enable-default-hash-style=gnu

# libiberty doesn't correctly detect these functions (I hate it here)
BINUTILS_CONFVARS := ac_cv_func_pstat_getdynaimc=no \
	ac_cv_func_pstat_getstatic=no \
	ac_cv_func_dup3=no \
	ac_cv_func___fsetlocking=no \
	ac_cv_func_getsysinfo=no \
	ac_cv_func_spawnve=no \
	ac_cv_func_spawnvpe=no \
	ac_cv_func_sysmp=no \
	ac_cv_func_table=no \
	ac_cv_func_pipe2=no \
	ac_cv_func_on_exit=no \
	ac_cv_func_mallinfo=no \
	ac_cv_func_mallinfo2=no \
	ac_cv_func_fallocate=no \
	ac_cv_func_posix_fallocate=no

binutils-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/binutils/binutils-$(BINUTILS_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,binutils-$(BINUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,binutils-$(BINUTILS_VERSION).tar.xz,binutils-$(BINUTILS_VERSION),binutils)
	$(call DO_PATCH,binutils,binutils,-p1)

ifneq ($(wildcard $(BUILD_WORK)/binutils/.build_complete),)
binutils:
	@echo "Using previously built binutils."
else
binutils: binutils-setup $(patsubst %,%-binutils-target,$(BINUTILS_TARGETS))
	touch $(BUILD_WORK)/binutils/.build_complete
endif

%-binutils-target: binutils-setup gettext
	target=$$(echo $@ | sed 's/-binutils-target//'); \
	if [ "$$GNU_HOST_TRIPLE" = "$$target" ]; then \
		binutils_extra_flags=--program-prefix=g; \
	fi; \
	if [ -f $(BUILD_WORK)/binutils/$$target/.build_complete ]; then \
		echo "Using previously built $$target binutils"; \
	else \
		mkdir -p $(BUILD_WORK)/binutils/$$target; \
		cd $(BUILD_WORK)/binutils/$$target && ../configure -C \
			$(DEFAULT_CONFIGURE_FLAGS) \
			--target=$$target \
			--libdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/$$target \
			$(BINUTILS_CONFARGS) $$binutils_extra_flags \
			CFLAGS="$(CFLAGS) -Doff64_t=off_t" \
			CPPFLAGS="$(CPPFLAGS) -Doff64_t=off_t" \
			LDFLAGS="$(LDFLAGS) -Wl,-flat_namespace,-undefined,dynamic_lookup" \
			$(BINUTILS_CONFARGS); \
		$(MAKE) -C $(BUILD_WORK)/binutils/$$target \
			$(BINUTILS_CONFVARS); \
		$(MAKE) -C $(BUILD_WORK)/binutils/$$target install \
			DESTDIR=$(BUILD_STAGE)/binutils/$$target; \
		if [ "$$(find $(BUILD_STAGE)/binutils/$$target/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin . -maxdepth 0 -empty -exec echo 1 \;)" = "1" ]; then \
			>&2 echo "Target $${target} is broken."; \
			exit 1; \
		else \
			$(call AFTER_BUILD,,binutils/$$target); \
		fi; \
	fi

binutils-package: binutils-stage
	# binutils.mk Package Structure
	for target in $(BINUTILS_TARGETS); do \
		rm -rf $(BUILD_DIST)/binutils-$$(sed -e 's/_/-/g' <<< "$$target"); \
		rm -rf $(BUILD_INFO)/binutils-$$(sed 's/_/-/g' <<< "$$target").control; \
	done
	rm -rf $(BUILD_DIST)/binutils{,-common}
	mkdir -p $(BUILD_DIST)/binutils
	mkdir -p $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	#  binutils.mk Prep binutils-*
	for target in $(BINUTILS_TARGETS); do \
		cp -a $(BUILD_STAGE)/binutils/$$target $(BUILD_DIST)/binutils-$$(sed -e 's/_/-/g' <<< "$$target"); \
		sed -e "s/@TARGET@/$$(sed -e 's/_/-/g' <<< "$$target")/g" $(BUILD_INFO)/binutils.control.in > $(BUILD_INFO)/binutils-$$(sed -e 's/_/-/g' <<< "$$target").control; \
	done
	cp -a $(BUILD_STAGE)/binutils/x86_64-linux-gnu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	for target in $(BINUTILS_TARGETS); do \
		for pkg in $(BUILD_DIST)/binutils-$$(sed -e 's/_/-/g' <<< "$$target"); do \
			for man in $$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/*; do \
				if [ "$(GNU_HOST_TRIPLE)" != "$$target" ]; then \
					$(LN_S) binutils-$$(basename $${man} | sed s'/'$$target'-//g') $$man; \
				else \
					$(LN_S) binutils-$$(basename $${man} | cut -d g -f2-) $$man; \
				fi; \
			done; \
			rm -rf $$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share/{locale,info}}; \
		done; \
	done
	for man in $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/*; do \
		mv $$man $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/binutils-$$(basename $$man | sed 's/x86_64-linux-gnu-//'); \
	done
	rm -rf $(BUILD_DIST)/binutils/*/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share,lib/!(ldscripts)}
	# binutils.mk Prep binutils,
	# No architecure-specific control mechanism in PACK, sorry.
	sed -e "s/@TARGET@/$$(sed -e 's/_/-/g' <<< "$(GNU_HOST_TRIPLE)")/g" $(BUILD_INFO)/binutils-native.control.in > $(BUILD_INFO)/binutils.control

	# binutils.mk Sign
	for target in $(BINUTILS_TARGETS); do \
		$(call SIGN,binutils-$$(sed -e 's/_/-/g' <<< "$$target"),general.xml);\
	done

	# binutils.mk Make .debs
	for target in $(BINUTILS_TARGETS); do \
		$(patsubst -if,if,$(call PACK,binutils-$$(sed -e 's/_/-/g' <<< "$$target"),DEB_BINUTILS_V)); \
	done
	$(call PACK,binutils,DEB_BINUTILS_V)
	$(call PACK,binutils-common,DEB_BINUTILS_V)

	# binutils.mk Build cleanup
	for target in $(BINUTILS_TARGETS); do \
		rm -rf $(BUILD_DIST)/binutils-$$(sed 's/_/-/g' <<< "$$target"); \
		rm $(BUILD_INFO)/binutils-$$(sed 's/_/-/g' <<< "$$target").control; \
	done
	rm -rf $(BUILD_DIST)/binutils{,-{,common}}
	rm $(BUILD_INFO)/binutils.control

.PHONY: binutils binutils-package
