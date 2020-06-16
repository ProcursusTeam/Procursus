ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += cctools
DOWNLOAD        += https://github.com/Diatrus/cctools-port/archive/$(CCTOOLS_VERSION)-ld64-$(LD64_VERSION).tar.gz
CCTOOLS_VERSION := 949.0.1
LD64_VERSION    := 530
DEB_CCTOOLS_V   ?= $(CCTOOLS_VERSION)

cctools-setup: setup
	$(call EXTRACT_TAR,$(CCTOOLS_VERSION)-ld64-$(LD64_VERSION).tar.gz,cctools-port-$(CCTOOLS_VERSION)-ld64-$(LD64_VERSION)/cctools,cctools)
	rm -rf $(BUILD_WORK)/cctools-*

ifneq ($(wildcard $(BUILD_WORK)/cctools/.build_complete),)
cctools:
	@echo "Using previously built cctools."
else
cctools: cctools-setup llvm uuid tapi xar
	cd $(BUILD_WORK)/cctools && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-lto-support \
		--with-libtapi="$(BUILD_STAGE)/tapi/usr" \
		CC="$(CC)" \
		CXX="$(CXX)" \
		CFLAGS='$(CFLAGS) -DHAVE_XAR_XAR_H' \
		CXXFLAGS='$(CXXFLAGS) -DHAVE_XAR_XAR_H' \
		LDFLAGS='$(LDFLAGS) -L$(BUILD_STAGE)/llvm/usr/lib/llvm-10/lib -lLTO'
	cp -a $(BUILD_STAGE)/llvm/usr/lib/llvm-10/include/llvm-c/{lto,ExternC}.h $(BUILD_WORK)/cctools/include/llvm-c
	+$(MAKE) -C $(BUILD_WORK)/cctools \
		XAR_LIB="-lxar" \
		UUID_LIB="-luuid" \
		LTO_DEF="-DLTO_SUPPORT"
	+$(MAKE) -C $(BUILD_WORK)/cctools install \
		DESTDIR=$(BUILD_STAGE)/cctools
	touch $(BUILD_WORK)/cctools/.build_complete
endif

cctools-package: cctools-stage
	# cctools.mk Package Structure
	rm -rf $(BUILD_DIST)/cctools
	mkdir -p $(BUILD_DIST)/cctools
	
	# cctools.mk Prep cctools
	cp -a $(BUILD_STAGE)/cctools/usr $(BUILD_DIST)/cctools
	
	# cctools.mk Sign
	$(call SIGN,cctools,general.xml)
	
	# cctools.mk Make .debs
	$(call PACK,cctools,DEB_CCTOOLS_V)
	
	# cctools.mk Build cleanup
	rm -rf $(BUILD_DIST)/cctools

.PHONY: cctools cctools-package
