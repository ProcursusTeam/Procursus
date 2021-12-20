ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += cctools
CCTOOLS_COMMIT  := 236a426c1205a3bfcf0dbb2e2faf2296f0a100e5
CCTOOLS_VERSION := 973.0.1
LD64_VERSION    := 609
DEB_CCTOOLS_V   ?= $(CCTOOLS_VERSION)-1
DEB_LD64_V      ?= $(LD64_VERSION)-2

cctools-setup: setup
	$(call GITHUB_ARCHIVE,tpoechtrager,cctools-port,$(CCTOOLS_COMMIT),$(CCTOOLS_COMMIT),cctools)
	$(call EXTRACT_TAR,cctools-$(CCTOOLS_COMMIT).tar.gz,cctools-port-$(CCTOOLS_COMMIT)/cctools,cctools)
	wget -q -nc -O$(BUILD_SOURCE)/ld64/ld64_wrapper.c https://git.elucubratus.com/elucubratus/elucubratus/-/raw/35cd7d96ef1bfc14a51463b4af6499cf7706fac5/data/ld64/wrapper.c
	$(call DO_PATCH,ld64,cctools,-p0)
	rm -rf $(BUILD_WORK)/cctools-*

ifneq ($(wildcard $(BUILD_WORK)/cctools/.build_complete),)
cctools:
	@echo "Using previously built cctools."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
cctools: cctools-setup llvm uuid tapi xar
else # (,$(findstring darwin,$(MEMO_TARGET)))
cctools: cctools-setup llvm uuid tapi xar ldid
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/cctools && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-tapi-support \
		--with-libtapi="$(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		CFLAGS="$(CFLAGS) -DLTO_SUPPORT=1 -DHAVE_XAR_XAR_H=1" \
		CXXFLAGS="$(CXXFLAGS) -DLTO_SUPPORT=1 -DHAVE_XAR_XAR_H=1" \
		LIBS="-lxar" # -DDEMANGLE_SWIFT=1
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/llvm-c/{lto,ExternC}.h $(BUILD_WORK)/cctools/include/llvm-c
	+$(MAKE) -C $(BUILD_WORK)/cctools
	+$(MAKE) -C $(BUILD_WORK)/cctools install \
		DESTDIR=$(BUILD_STAGE)/cctools
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	mv $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld64
else
	# Use a wrapper program on iOS for automatically call ldid
	cp $(BUILD_SOURCE)/ld64_wrapper.c $(BUILD_WORK)/cctools/ld64/
	$(SED) -i "s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g" $(BUILD_WORK)/cctools/ld64/ld64_wrapper.c
	mkdir -p $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{libexec,share/entitlements}
	mv $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ld64
	$(CC) $(BUILD_WORK)/cctools/ld64/ld64_wrapper.c -o $(BUILD_WORK)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld64 $(LDFLAGS)
	cp $(BUILD_MISC)/entitlements/general.xml $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/entitlements/ld64.xml
endif
	$(call AFTER_BUILD)
endif

cctools-package: cctools-stage
	# cctools.mk Package Structure
	rm -rf $(BUILD_DIST)/{cctools,ld64}
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/{cctools,ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}}
else
	mkdir -p $(BUILD_DIST)/{cctools,ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec,share/{entitlements,man/man1}}}
endif

	# cctools.mk Prep cctools
	cp -a $(BUILD_STAGE)/cctools $(BUILD_DIST)

	# cctools.mk Prep ld64
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{dyldinfo,ld64,machocheck,ObjectDump,unwinddump} $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ld64 $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/entitlements/ld64.xml $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/entitlements
endif
	mv $(BUILD_DIST)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{dyldinfo,ld{,64},unwinddump}.1 $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cd $(BUILD_DIST)/ld64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin && $(LN_S) ld64 ld

	# cctools.mk Sign
	$(call SIGN,cctools,general.xml)
	$(call SIGN,ld64,general.xml)

	# cctools.mk Make .debs
	$(call PACK,cctools,DEB_CCTOOLS_V)
	$(call PACK,ld64,DEB_LD64_V)

	# cctools.mk Build cleanup
	rm -rf $(BUILD_DIST)/{cctools,ld64}

.PHONY: cctools cctools-package
