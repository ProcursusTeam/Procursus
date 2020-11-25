ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += p7zip
P7ZIP_VERSION  := 16.02
DEBIAN_P7ZIP_V := $(P7ZIP_VERSION)+dfsg-8
DEB_P7ZIP_V    ?= $(DEBIAN_P7ZIP_V)

p7zip-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://deb.debian.org/debian/pool/main/p/p7zip/p7zip_$(P7ZIP_VERSION)+dfsg.orig.tar.xz \
		https://deb.debian.org/debian/pool/main/p/p7zip/p7zip_$(DEBIAN_P7ZIP_V).debian.tar.xz \
		https://raw.githubusercontent.com/shirkdog/hardenedbsd-ports/master/archivers/p7zip/files/patch-CPP_Windows_ErrorMsg.cpp
	$(call EXTRACT_TAR,p7zip_$(P7ZIP_VERSION)+dfsg.orig.tar.xz,p7zip_$(P7ZIP_VERSION),p7zip)
	$(call EXTRACT_TAR,p7zip_$(DEBIAN_P7ZIP_V).debian.tar.xz,debian/patches,$(BUILD_PATCH)/p7zip-$(P7ZIP_VERSION))
	rm -rf $(BUILD_WORK)/debian
	cp $(BUILD_SOURCE)/patch-CPP_Windows_ErrorMsg.cpp $(BUILD_PATCH)/p7zip-$(P7ZIP_VERSION)
	$(SED) -i 's|CPP/Windows|p7zip/CPP/Windows|' $(BUILD_PATCH)/p7zip-$(P7ZIP_VERSION)/patch-CPP_Windows_ErrorMsg.cpp
	$(call DO_PATCH,p7zip-$(P7ZIP_VERSION),p7zip,-p1)

ifneq ($(wildcard $(BUILD_WORK)/p7zip/.build_complete),)
p7zip:
	@echo "Using previously built p7zip."
else
p7zip: p7zip-setup
	$(SED) -i 's/ifdef __APPLE_CC__/if 0\/\/__APPLE_CC__/g' $(BUILD_WORK)/p7zip/CPP/Windows/DLL.cpp
	cd $(BUILD_WORK)/p7zip && mv -f makefile.macosx_gcc_64bits makefile.machine
	+$(MAKE) -C $(BUILD_WORK)/p7zip all3 \
		CC="$(CC) $(CFLAGS)" \
		CXX="$(CXX) $(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/p7zip install \
		DEST_DIR=$(BUILD_STAGE)/p7zip \
		DEST_HOME=/usr
	touch $(BUILD_WORK)/p7zip/.build_complete
endif

p7zip-package: p7zip-stage
	# p7zip.mk Package Structure
	rm -rf $(BUILD_DIST)/p7zip
	mkdir -p $(BUILD_DIST)/p7zip
	
	# p7zip.mk Prep p7zip
	cp -a $(BUILD_STAGE)/p7zip/usr $(BUILD_DIST)/p7zip
	rm -rf $(BUILD_DIST)/p7zip/usr/man
	
	# p7zip.mk Sign
	$(call SIGN,p7zip,general.xml)
	
	# p7zip.mk Make .debs
	$(call PACK,p7zip,DEB_P7ZIP_V)
	
	# p7zip.mk Build cleanup
	rm -rf $(BUILD_DIST)/p7zip

.PHONY: p7zip p7zip-package
