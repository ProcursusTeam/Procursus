ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += cctools
CCTOOLS_COMMIT  := 6262802c55660436c49c52f323c2db9900a900ae
LD64_COMMIT     := eac639ff5e0104c57343a0342650294ad37fa510
CCTOOLS_VERSION := 1010.6
LD64_VERSION    := 951.9
DEB_CCTOOLS_V   ?= $(CCTOOLS_VERSION)-1
DEB_LD64_V      ?= $(LD64_VERSION)-1

cctools-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,cctools,$(CCTOOLS_COMMIT),$(CCTOOLS_COMMIT))
	$(call GITHUB_ARCHIVE,ProcursusTeam,ld64,$(LD64_COMMIT),$(LD64_COMMIT))
	$(call EXTRACT_TAR,cctools-$(CCTOOLS_COMMIT).tar.gz,cctools-$(CCTOOLS_COMMIT),cctools)
	mkdir -p $(BUILD_WORK)/cctools/subprojects
	$(call EXTRACT_TAR,ld64-$(LD64_COMMIT).tar.gz,ld64-$(LD64_COMMIT),cctools/subprojects/ld64)
	mkdir -p $(BUILD_WORK)/cctools/build
	echo -e "[host_machine]\n \
	system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	llvm-config = '$(shell command -v llvm-config)'\n \
	cmake = '$(shell command -v cmake)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/cctools/build/cross.txt
	sed -i 's|\[_trieBytes|[-1+_trieBytes|g' $(BUILD_WORK)/cctools/subprojects/ld64/src/mach_o/ExportsTrie.cpp
	sed -i 's|0 NULL|0, NULL|g' $(BUILD_WORK)/cctools/EXTERNAL_HEADERS/libcodedirectory.c

ifneq ($(wildcard $(BUILD_WORK)/cctools/.build_complete),)
cctools:
	@echo "Using previously built cctools."
else
cctools: cctools-setup llvm uuid tapi xar
	cd $(BUILD_WORK)/cctools/build && LIBRARY_PATH="$(TARGET_SYSROOT)/usr/lib:$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" meson setup \
		--cross-file cross.txt \
		-Dld64:supported-archs="x86_64,x86_64h,i386,armv4t,armv5,armv6,armv7,armv7f,armv7k,armv7s,armv6m,armv7m,armv7em,armv8,arm64,arm64e,arm64v8,arm64_32,riscv" \
		..
	cd $(BUILD_WORK)/cctools/build; \
		DESTDIR="$(BUILD_STAGE)/cctools" meson install
	$(call AFTER_BUILD)
endif

cctools-package: cctools-stage
	# cctools.mk Package Structure
	rm -rf $(BUILD_DIST)/{cctools,ld64}
	mkdir -p $(BUILD_DIST)/{cctools,ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}}

	# cctools.mk Prep cctools
	cp -a $(BUILD_STAGE)/cctools $(BUILD_DIST)

	# cctools.mk Prep ld64
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{ld64,machocheck,ObjectDump,objcimageinfo,unwinddump} $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{ld{64,-classic},unwinddump}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	rm -f $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld
	$(LN_S) ld-classic.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/ld64.1$(MEMO_MANPAGE_SUFFIX)
	$(LN_S) ld64 $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld
	$(LN_S) ld64 $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld-classic

	# cctools.mk Sign
	$(call SIGN,cctools,general.xml)
	$(call SIGN,ld64,general.xml)

	# cctools.mk Make .debs
	$(call PACK,cctools,DEB_CCTOOLS_V)
	$(call PACK,ld64,DEB_LD64_V)

	# cctools.mk Build cleanup
	rm -rf $(BUILD_DIST)/{cctools,ld64}

.PHONY: cctools cctools-package
