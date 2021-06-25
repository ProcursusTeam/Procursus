ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += cctools
CCTOOLS_COMMIT  := 236a426c1205a3bfcf0dbb2e2faf2296f0a100e5
CCTOOLS_VERSION := 973.0.1
LD64_VERSION    := 609
DEB_CCTOOLS_V   ?= $(CCTOOLS_VERSION)
DEB_LD64_V      ?= $(LD64_VERSION)

cctools-setup: setup
	$(call GITHUB_ARCHIVE,tpoechtrager,cctools-port,$(CCTOOLS_COMMIT),$(CCTOOLS_COMMIT),cctools)
	$(call EXTRACT_TAR,cctools-$(CCTOOLS_COMMIT).tar.gz,cctools-port-$(CCTOOLS_COMMIT)/cctools,cctools)
	$(call DO_PATCH,ld64,cctools,-p0)
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' \
		-e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		-e 's|@BARE_PLATFORM@|$(BARE_PLATFORM)|g' \
		$(BUILD_WORK)/cctools/ld64/src/ld/Options.cpp
	rm -rf $(BUILD_WORK)/cctools-*

ifneq ($(wildcard $(BUILD_WORK)/cctools/.build_complete),)
cctools:
	@echo "Using previously built cctools."
else
cctools: cctools-setup llvm uuid tapi xar
	cd $(BUILD_WORK)/cctools && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-tapi-support \
		--with-libtapi="$(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		CFLAGS="$(CFLAGS) -DLTO_SUPPORT=1 -DHAVE_XAR_XAR_H=1" \
		CXXFLAGS="$(CXXFLAGS) -DLTO_SUPPORT=1 -DHAVE_XAR_XAR_H=1" \
		LIBS="-lxar $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libLTO.dylib"
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-11/include/llvm-c/{lto,ExternC}.h $(BUILD_WORK)/cctools/include/llvm-c
	+$(MAKE) -C $(BUILD_WORK)/cctools
	+$(MAKE) -C $(BUILD_WORK)/cctools install \
		DESTDIR=$(BUILD_STAGE)/cctools
	mv $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	$(CC) $(CFLAGS) -DLINKER="\""$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ld"\"" \
		-DLDID="\""$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ldid"\"" \
		-DENTS="\""$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/entitlements/general.xml"\"" \
		-o $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld $(BUILD_MISC)/ld-wrapper/wrapper.c
	touch $(BUILD_WORK)/cctools/.build_complete
endif

cctools-package: cctools-stage
	# cctools.mk Package Structure
	rm -rf $(BUILD_DIST)/{cctools,ld64}
	mkdir -p $(BUILD_DIST)/{cctools,ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec,share/{entitlements,man/man1}}}

	# cctools.mk Prep cctools
	cp -a $(BUILD_STAGE)/cctools $(BUILD_DIST)

	# cctools.mk Prep ld64
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{dyldinfo,ld,machocheck,ObjectDump,unwinddump} $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{dyldinfo,ld{,64},unwinddump}.1 $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ld $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_INFO)/general.xml $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/entitlements
	cd $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin && ln -s ld ld64

	# cctools.mk Sign
	$(call SIGN,cctools,general.xml)
	$(call SIGN,ld64,general.xml)

	# cctools.mk Make .debs
	$(call PACK,cctools,DEB_CCTOOLS_V)
	$(call PACK,ld64,DEB_LD64_V)

	# cctools.mk Build cleanup
	rm -rf $(BUILD_DIST)/{cctools,ld64}

.PHONY: cctools cctools-package
