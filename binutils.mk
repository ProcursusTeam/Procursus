ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += binutils
BINUTILS_VERSION := 2.36.1
DEB_BINUTILS_V   ?= $(BINUTILS_VERSION)

BINUTILS_TARGETS := aarch64-freebsd aarch64-linux-gnu aarch64-linux-musl aarch64-openbsd aarch64_be-netbsd alpha-linux-gnu alpha-linux-musl alpha-openbsd arm-linux-gnueabi arm-linux-gnueabihf arm-linux-musl arm-netbsd armeb-netbsd armv4-netbsd armv4eb-netbsd armv6-netbsd armv6eb-netbsd armv7-netbsd armv7-openbsd armv7eb-netbsd i386-freebsd i386-openbsd i486-netbsd i686-gnu i686-kfreebsd-gnu i686-linux-gnu i686-linux-musl ia64-linux-gnu ia64-linux-musl m68010-netbsd m68k-linux-gnu m68k-linux-musl mips64-netbsd mips64el-linux-gnuabi64 mips64el-linux-musl mipsel-linux-gnu mipsel-linux-musl powerpc-freebsd powerpc-linux-gnu powerpc-linux-musl powerpc64-freebsd powerpc64-linux-gnu powerpc64-linux-musl powerpc64-openbsd powerpc64le-linux-gnu powerpc64le-linux-musl powerpcspe-freebsd riscv64-linux-gnu riscv64-linux-musl s390x-linux-gnu s390x-linux-musl sh-netbsd sh4-linux-gnu sh4-linux-musl shle-netbsd sparc64-freebsd sparc64-linux-gnu sparc64-linux-musl sparc64-openbsd x86_64-freebsd x86_64-linux-gnu x86_64-linux-musl x86_64-netbsd x86_64-openbsd

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

binutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/binutils/binutils-$(BINUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,binutils-$(BINUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,binutils-$(BINUTILS_VERSION).tar.xz,binutils-$(BINUTILS_VERSION),binutils)
	$(call DO_PATCH,binutils,binutils,-p1)

ifneq ($(wildcard $(BUILD_WORK)/binutils/.build_complete),)
binutils:
	@echo "Using previously built binutils."
else
binutils: binutils-setup gettext
	for target in $(BINUTILS_TARGETS); do \
		mkdir -p $(BUILD_WORK)/binutils/$$target; \
		cd $(BUILD_WORK)/binutils/$$target && ../configure -C \
			--build=$$($(BUILD_MISC)/config.guess) \
			--host=$(GNU_HOST_TRIPLE) \
			--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
			--libdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/$(GNU_HOST_TRIPLE)/$$target/lib \
			--includedir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/$(GNU_HOST_TRIPLE)/$$target/include \
			--target=$$target \
			$(BINUTILS_CONFARGS); \
		$(MAKE) -C $(BUILD_WORK)/binutils/$$target; \
		$(MAKE) -C $(BUILD_WORK)/binutils/$$target install \
			DESTDIR=$(BUILD_STAGE)/binutils/$$target; \
	done
	touch $(BUILD_WORK)/binutils/.build_complete
endif

binutils-package: binutils-stage
	# binutils.mk Package Structure
	for target in $(BINUTILS_TARGETS); do \
		rm -rf $(BUILD_DIST)/binutils-$$target; \
	done
	rm -rf $(BUILD_DIST)/binutils-common
	mkdir -p $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# binutils.mk Prep binutils-*
	for target in $(BINUTILS_TARGETS); do \
		cp -r $(BUILD_STAGE)/binutils/$$target $(BUILD_DIST)/binutils-$$target; \
	done
	for target in $(BINUTILS_TARGETS); do \
		for pkg in $(BUILD_DIST)/binutils-$$target; do \
			for man in $$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/*; do \
				$(LN) -sf binutils-$$(basename $$man .1 | rev | cut -d- -f1 | rev ).1.zst $$man; \
			done; \
			rm -rf $$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{locale,info}; \
		done; \
	done
	cp -r $(BUILD_STAGE)/binutils/x86_64-linux-gnu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	for man in $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/*; do \
		mv $$man $(BUILD_DIST)/binutils-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/binutils-$$(basename $$man .1 | rev | cut -d- -f1 | rev ).1; \
	done
	
	# binutils.mk Sign
	for target in $(BINUTILS_TARGETS); do \
		$(call SIGN,binutils-$$target,general.xml);\
	done
	
	# Make control files with:
	# sed "s/@TARGET@/$(sed 's/_/-/g' <<< "$target")/g" binutils.control.in > binutils-$target.control
	
	# binutils.mk Make .debs
	-for target in $(BINUTILS_TARGETS); do \
		$(patsubst -if,if,$(call PACK,binutils-$$target,DEB_BINUTILS_V)); \
	done
	$(call PACK,binutils-common,DEB_BINUTILS_V)
	
	# binutils.mk Build cleanup
	for target in $(BINUTILS_TARGETS); do \
		rm -rf $(BUILD_DIST)/binutils-$$target; \
	done
	rm -rf $(BUILD_DIST)/binutils-common

.PHONY: binutils binutils-package
