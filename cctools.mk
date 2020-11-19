ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS    += cctools
CCTOOLS_VERSION := 949.0.1
LD64_VERSION    := 530
DEB_CCTOOLS_V   ?= $(CCTOOLS_VERSION)-2
DEB_LD64_V      ?= $(LD64_VERSION)-3

cctools-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/Diatrus/cctools-port/archive/$(CCTOOLS_VERSION)-ld64-$(LD64_VERSION).tar.gz
	$(call EXTRACT_TAR,$(CCTOOLS_VERSION)-ld64-$(LD64_VERSION).tar.gz,cctools-port-$(CCTOOLS_VERSION)-ld64-$(LD64_VERSION)/cctools,cctools)
	rm -rf $(BUILD_WORK)/cctools-*

ifneq ($(wildcard $(BUILD_WORK)/cctools/.build_complete),)
cctools:
	@echo "Using previously built cctools."
else
cctools: cctools-setup llvm uuid tapi xar
	cd $(BUILD_WORK)/cctools && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--enable-lto-support \
		--with-libtapi="$(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		CC="$(CC)" \
		CXX="$(CXX)" \
		CFLAGS='$(CFLAGS) -DHAVE_XAR_XAR_H' \
		CXXFLAGS='$(CXXFLAGS) -DHAVE_XAR_XAR_H' \
		LDFLAGS='$(LDFLAGS) $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libLTO.dylib'
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-10/include/llvm-c/{lto,ExternC}.h $(BUILD_WORK)/cctools/include/llvm-c
	+$(MAKE) -C $(BUILD_WORK)/cctools \
		XAR_LIB="-lxar" \
		UUID_LIB="-luuid" \
		LTO_DEF="-DLTO_SUPPORT"
	+$(MAKE) -C $(BUILD_WORK)/cctools install \
		DESTDIR=$(BUILD_STAGE)/cctools
	mv $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/cctools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ld $(BUILD_INFO)/wrapper.c
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
