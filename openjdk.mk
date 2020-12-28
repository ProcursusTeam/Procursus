ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += openjdk
OPENJDK_COMMIT  := 8383f41ca7faa59dab17f6bb47fecd5a93ab72e3
OPENJDK_MAJOR_V := 16
OPENJDK_VERSION := $(OPENJDK_MAJOR_V).0.0+git20201217.$(shell echo $(OPENJDK_COMMIT) | cut -c -7)
DEB_OPENJDK_V   ?= $(OPENJDK_VERSION)-1

openjdk-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/openjdk-$(OPENJDK_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/openjdk-$(OPENJDK_COMMIT).tar.gz \
			https://github.com/openjdk/aarch64-port/archive/$(OPENJDK_COMMIT).tar.gz
	wget -q -nc -P $(BUILD_SOURCE) \
		https://github.com/apple/cups/releases/download/v2.3.3/cups-2.3.3-source.tar.gz \
		https://download.java.net/java/GA/jdk15/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-15_osx-x64_bin.tar.gz
		#https://download.java.net/java/GA/jdk15/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-15_linux-x64_bin.tar.gz
	$(call EXTRACT_TAR,openjdk-$(OPENJDK_COMMIT).tar.gz,aarch64-port-$(OPENJDK_COMMIT),openjdk)
	$(call EXTRACT_TAR,cups-2.3.3-source.tar.gz,cups-2.3.3,apple-cups)
	$(call EXTRACT_TAR,openjdk-15_osx-x64_bin.tar.gz,jdk-15.jdk,boot-jdk.jdk) # Change this to use the Linux one on Linux
ifneq ($(MEMO_TARGET),darwin-arm64e)
	$(call DO_PATCH,openjdk-ios,openjdk,-p1)
	$(SED) -i 's|<Cocoa/Cocoa.h>|<Foundation/Foundation.h>|' $(BUILD_WORK)/openjdk/src/java.base/macosx/native/libjli/java_md_macosx.m
	$(SED) -i '/<CoreServices\/CoreServices.h>/a #include <CFNetwork/CFNetwork.h>' $(BUILD_WORK)/openjdk/src/java.base/macosx/native/libnet/DefaultProxySelector.c
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
	$(call DO_PATCH,openjdk-pre1700,openjdk,-p1)
endif
endif

ifneq ($(wildcard $(BUILD_WORK)/openjdk/.build_complete),)
openjdk:
	@echo "Using previously built openjdk."
else
openjdk: openjdk-setup
	rm -rf $(BUILD_STAGE)/openjdk
	mkdir -p $(BUILD_STAGE)/openjdk/usr/lib/jvm
	chmod 0755 $(BUILD_WORK)/openjdk/configure
	cd $(BUILD_WORK)/openjdk && ./configure \
		--prefix=/usr/lib \
		--openjdk-target=$(GNU_HOST_TRIPLE) \
		--with-extra-cflags="$(CFLAGS)" \
		--with-extra-cxxflags="$(CXXFLAGS)" \
		--with-extra-ldflags="$(LDFLAGS) -headerpad_max_install_names" \
		--with-sysroot="$(TARGET_SYSROOT)" \
		--with-cups-include="$(BUILD_WORK)/apple-cups" \
		--without-version-pre \
		--without-version-opt \
		--with-boot-jdk="$(BUILD_WORK)/boot-jdk.jdk/Contents/Home" \
		--with-debug-level=release \
		--with-native-debug-symbols=none \
		--with-jvm-variants=server \
		CPP="$(CPP) -arch arm64" \
		CXXCPP="$(CXX) -E -arch arm64"
	make -C $(BUILD_WORK)/openjdk images \
		JOBS=$(shell $(GET_LOGICAL_CORES))
	cp -a $(BUILD_WORK)/openjdk/build/*/images/jdk $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk
	touch $(BUILD_WORK)/openjdk/.build_complete
endif

openjdk-package: openjdk-stage
	# openjdk.mk Package Structure
	rm -rf $(BUILD_DIST)/openjdk*-{jre,jdk}
	mkdir -p $(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-{jre,jdk}/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/{bin,lib,man/man1} \
		mkdir -p $(BUILD_DIST)/openjdk-{jre,jdk}/usr/{bin,share/man/man1}
	
	# openjdk.mk Prep openjdk-$(OPENJDK_MAJOR_V)-jre
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/{java,jfr,keytool,rmid,rmiregistry} \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin
	for bin in $(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/*; do \
		$(I_N_T) -add_rpath /usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib $$bin; \
	done
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/{java,jfr,keytool,rmid,rmiregistry}.1 \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/{conf,legal} \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib/!(src.zip) \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jre/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib

	# openjdk.mk Prep openjdk-jre
	for bin in java jfr keytool rmid rmiregistry; do \
		ln -sf ../lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/$${bin} $(BUILD_DIST)/openjdk-jre/usr/bin/$${bin}; \
		ln -sf ../../../lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/$${bin}.1 $(BUILD_DIST)/openjdk-jre/usr/share/man/man1/$${bin}.1; \
	done

	# openjdk.mk Prep openjdk-jdk
	for bin in jar jarsigner javac javadoc javap jcmd jconsole jdb jdeprscan jdeps jhsdb jimage jinfo jlink jmap jmod jpackage jps jrunscript jshell jstack jstat jstatd serialver; do \
		ln -sf ../lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/$${bin} $(BUILD_DIST)/openjdk-jdk/usr/bin/$${bin}; \
		ln -sf ../../../lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/$${bin}.1 $(BUILD_DIST)/openjdk-jdk/usr/share/man/man1/$${bin}.1; \
	done
	
	# openjdk.mk Prep openjdk-$(OPENJDK_MAJOR_V)-jdk
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/!(java|jfr|keytool|rmid|rmiregistry) \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin
	for bin in $(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/bin/*; do \
		$(I_N_T) -add_rpath /usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib $$bin; \
	done
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/{include,jmods} \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib/src.zip \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/lib
	cp -a $(BUILD_STAGE)/openjdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1/!(java.1|jfr.1|keytool.1|rmid.1|rmiregistry.1) \
		$(BUILD_DIST)/openjdk-$(OPENJDK_MAJOR_V)-jdk/usr/lib/jvm/java-$(OPENJDK_MAJOR_V)-openjdk/man/man1

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
