ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += openjdk
OPENJDK_MAJOR_V  := 17
OPENJDK_REVISION := 16
OPENJDK_VERSION  := $(OPENJDK_MAJOR_V)+$(OPENJDK_REVISION)
DEB_OPENJDK_V    ?= $(OPENJDK_VERSION)

# Change "ea" to nothing on general availability...

OPENJDK_VENDOR_ARGS := --with-version-pre=ea \
		--without-version-opt \
		--with-vendor-bug-url="https://github.com/ProcursusTeam/Procursus/issues" \
		--with-vendor-name=Procursus \
		--with-vendor-url="https://github.com/ProcursusTeam/Procursus" \
		--with-vendor-version-string=Procursus \
		--with-vendor-vm-bug-url="https://github.com/ProcursusTeam/Procursus/issues" \
		--with-version-build="$(OPENJDK_REVISION)" \

###
# The patches are still horribly ugly, please pay no mind.
# TODO: Try and get libjsound working.
###

openjdk-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/openjdk/jdk/archive/refs/tags/jdk-$(OPENJDK_VERSION).tar.gz
	wget -q -nc -P $(BUILD_SOURCE) \
		https://github.com/apple/cups/releases/download/v2.3.3/cups-2.3.3-source.tar.gz \
		https://download.java.net/java/GA/jdk15/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-15_osx-x64_bin.tar.gz
		#https://download.java.net/java/GA/jdk15/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-15_linux-x64_bin.tar.gz
	$(call EXTRACT_TAR,jdk-$(OPENJDK_VERSION).tar.gz,jdk-jdk-$(OPENJDK_MAJOR_V)-$(OPENJDK_REVISION),openjdk)
	$(call EXTRACT_TAR,cups-2.3.3-source.tar.gz,cups-2.3.3,apple-cups)
	$(call EXTRACT_TAR,openjdk-15_osx-x64_bin.tar.gz,jdk-15.jdk,boot-jdk.jdk) # Change this to use the Linux one on Linux
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,openjdk-ios,openjdk,-p1)
	$(SED) -i '/<CoreServices\/CoreServices.h>/a #include <CFNetwork/CFNetwork.h>' $(BUILD_WORK)/openjdk/src/java.base/macosx/native/libnet/DefaultProxySelector.c
	for file in $(BUILD_WORK)/openjdk/src/java.base/macosx/native/libjli/java_md_macosx.m \
	$(BUILD_WORK)/openjdk/src/java.desktop/macosx/native/libawt_lwawt/awt/LWCToolkit.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/macosx/native/libawt_lwawt/awt/AWTWindow.m \
	$(BUILD_WORK)/openjdk/src/java.desktop/macosx/native/libawt_lwawt/awt/ApplicationDelegate.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/macosx/native/libawt_lwawt/awt/CDataTransferer.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/macosx/native/libawt_lwawt/java2d/opengl/J2D_GL/cglext.h \
	$(BUILD_WORK)/openjdk/src/java.security.jgss/macosx/native/libosxkrb5/SCDynamicStoreConfig.m \
	$(BUILD_WORK)/openjdk/src/java.base/macosx/native/libosxsecurity/KeystoreImpl.m; do \
		$(SED) -i 's|<Cocoa/Cocoa.h>|<Foundation/Foundation.h>|' $$file; \
	done
	for file in $(BUILD_WORK)/openjdk/src/java.desktop/share/native/libfontmanager/hb-jdk-font.c \
	$(BUILD_WORK)/openjdk/src/java.desktop/share/native/libfontmanager/HBShaper.c \
	$(BUILD_WORK)/openjdk/src/java.desktop/share/native/common/java2d/opengl/OGLFuncs.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/share/native/libmlib_image/mlib_image.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/share/native/libmlib_image/mlib_types.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/share/native/libmlib_image/mlib_ImageAffine.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/share/native/common/java2d/opengl/OGLBlitLoops.c \
	$(BUILD_WORK)/openjdk/src/java.desktop/unix/native/libawt/awt/awt_LoadLibrary.c \
	$(BUILD_WORK)/openjdk/src/java.desktop/unix/native/common/awt/color.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/unix/native/common/awt/utility/rect.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/unix/native/common/awt/awt.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/unix/native/common/awt/img_util_md.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/unix/native/libawt/java2d/j2d_md.h \
	$(BUILD_WORK)/openjdk/src/java.desktop/unix/native/common/java2d/opengl/OGLFuncs_md.h; do \
		$(SED) -i 's|MACOSX|MACOSXXXXXX|' $$file; \
	done
	cp $(BUILD_WORK)/openjdk/make/data/charsetmapping/stdcs-linux $(BUILD_WORK)/openjdk/make/data/charsetmapping/stdcs-macosx
	rm -rf $(BUILD_WORK)/openjdk/src/java.desktop/macosx/
endif

ifneq ($(wildcard $(BUILD_WORK)/openjdk/.build_complete),)
openjdk:
	@echo "Using previously built openjdk."
else
openjdk: openjdk-setup libx11 libxext libxi libxrender libxrandr libxtst freetype libgif harfbuzz lcms2 libpng16 xorgproto
	rm -rf $(BUILD_STAGE)/openjdk
	mkdir -p $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm
	chmod 0755 $(BUILD_WORK)/openjdk/configure
	cd $(BUILD_WORK)/openjdk && ./configure \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--openjdk-target=$(GNU_HOST_TRIPLE) \
		--with-extra-cflags="$(CFLAGS) -DTARGET_OS_OSX" \
		--with-extra-cxxflags="$(CXXFLAGS) -DTARGET_OS_OSX" \
		--with-extra-ldflags="$(LDFLAGS) -headerpad_max_install_names" \
		--with-sysroot="$(TARGET_SYSROOT)" \
		$(OPENJDK_VENDOR_ARGS) \
		--with-boot-jdk="$(BUILD_WORK)/boot-jdk.jdk/Contents/Home" \
		--with-debug-level=release \
		--with-native-debug-symbols=none \
		--with-jvm-variants=server \
		--with-x=system \
		--with-cups-include="$(BUILD_WORK)/apple-cups" \
		--with-fontconfig=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-freetype=system \
		--with-freetype-lib=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--with-freetype-include=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--with-libjpeg=system \
		--with-giflib=system \
		--with-libpng=system \
		--with-zlib=system \
		--with-lcms=system \
		--with-harfbuzz=system \
		CPP="$(CPP) -arch arm64" \
		CXXCPP="$(CXX) -E -arch arm64"
	make -C $(BUILD_WORK)/openjdk images \
		JOBS=$(shell $(GET_LOGICAL_CORES))
	cp -a $(BUILD_WORK)/openjdk/build/*/images/jdk $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk
	for dylib in $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib/{,*/}*.dylib; do \
		ln -sf $$(basename $$dylib) $$(echo $$dylib | $(SED) s/.dylib//).so; \
	done
	touch $(BUILD_WORK)/openjdk/.build_complete
endif

openjdk-package: openjdk-stage
	# openjdk.mk Package Structure
	rm -rf $(BUILD_DIST)/openjdk*-{jre,jdk}
	mkdir -p $(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-{jre,jdk}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/{bin,lib,man/man1} \
		mkdir -p $(BUILD_DIST)/openjdk-{jre,jdk}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# openjdk.mk Prep openjdk-$(OPENJDK_MAJOR_V)-jre
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/{java,jfr,keytool,rmid,rmiregistry} \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin
	for bin in $(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/*; do \
		$(I_N_T) -add_rpath /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib $$bin; \
	done
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/{java,jfr,keytool,rmid,rmiregistry}.1 \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/{conf,legal} \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib/!(src.zip) \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib

	# openjdk.mk Prep openjdk-jre
	for bin in java jfr keytool rmid rmiregistry; do \
		ln -sf $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/$${bin} $(BUILD_DIST)/openjdk-jre/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin}; \
		ln -sf $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/$${bin}.1 $(BUILD_DIST)/openjdk-jre/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$${bin}.1; \
	done

	# openjdk.mk Prep openjdk-jdk
	for bin in jar jarsigner javac javadoc javap jcmd jconsole jdb jdeprscan jdeps jhsdb jimage jinfo jlink jmap jmod jpackage jps jrunscript jshell jstack jstat jstatd serialver; do \
		ln -sf $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/$${bin} $(BUILD_DIST)/openjdk-jdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin}; \
		ln -sf $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/$${bin}.1 $(BUILD_DIST)/openjdk-jdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$${bin}.1; \
	done

	# openjdk.mk Prep openjdk-$(OPENJDK_MAJOR_V)-jdk
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/!(java|jfr|keytool|rmid|rmiregistry) \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin
	for bin in $(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/*; do \
		$(I_N_T) -add_rpath /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib $$bin; \
	done
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/{include,jmods} \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib/src.zip \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib
	cp -a $(BUILD_STAGE)/openjdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/!(java.1|jfr.1|keytool.1|rmid.1|rmiregistry.1) \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1

	# openjdk.mk Sign
	$(call SIGN,openjdk-$(OPENJDK_MAJOR_V)-jdk,qemu-ios.xml)
	$(call SIGN,openjdk-$(OPENJDK_MAJOR_V)-jre,qemu-ios.xml)

	# openjdk.mk Make .debs
	$(call PACK,openjdk-$(OPENJDK_MAJOR_V)-jdk,DEB_OPENJDK_V)
	$(call PACK,openjdk-$(OPENJDK_MAJOR_V)-jre,DEB_OPENJDK_V)
	$(call PACK,openjdk-jdk,DEB_OPENJDK_V)
	$(call PACK,openjdk-jre,DEB_OPENJDK_V)

	# openjdk.mk Build cleanup
	rm -rf $(BUILD_DIST)/openjdk*-{jre,jdk}

.PHONY: openjdk openjdk-package
