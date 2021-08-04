ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += base-files
BASE-FILES_VERSION  := 11.1
DEB_BASE-FILES_V    ?= $(BASE-FILES_VERSION)

MEMO_VERSION_STRING ?= $(MEMO_VERSION_ID) Darwin/$(DARWIN_DEPLOYMENT_VERSION) ($(MEMO_CODENAME))
MEMO_DEBIAN_VERSION ?= bullseye/sid

base-files-setup:
	wget -q -nc -P$(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/b/base-files/base-files_11.1.tar.xz
	$(call EXTRACT_TAR,base-files_$(BASE-FILES_VERSION).tar.xz,base-files-$(BASE-FILES_VERSION),base-files)
	rm -rf $(BUILD_WORK)/base-files/motd

ifneq ($(wildcard $(BUILD_WORK)/base-files/.build_complete),)
base-files:
        @echo "Using previously built base-files."
else
base-files: base-files-setup
	mkdir -p $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/{doc,base-files},lib}
	mkdir -p $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)/etc/{update-motd.d,dpkg/origins}
	cp -a $(BUILD_WORK)/base-files/licenses $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/common-licenses
	$(INSTALL) -m644 $(BUILD_MISC)/base-files/APSL-2.0 $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/common-licenses
	echo $(MEMO_DEBIAN_VERSION) > $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)/etc/debian_version
	chmod 644 $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)/etc/debian_version
	for file in host.conf issue issue.net os-release motd procursus profile dot.profile dot.bashrc; \
	do $(SED) \
		-e 's|@MEMO_VERSION_ID@|$(MEMO_VERSION_ID)|g' \
		-e 's|@DARWIN_DEVELOPMEMT_VERSION@|$(DARWIN_DEVELOPMENT_VERSION)|g' \
		-e 's|@MEMO_HOME_URI@|$(MEMO_HOME_URI)|g' \
		-e 's|@MEMO_BUGS_URI@|$(MEMO_BUGS_URI)|g' \
		-e 's|@MEMO_SUPPORT_URI@|$(MEMO_SUPPORT_URI)|g' \
		-e 's|@MEMO_REPO_URI@|$(MEMO_REPO_URI)|g' \
		-e 's|@MEMO_VENDOR@|$(MEMO_VENDOR)|g' \
		-e 's|@MEMO_VENDOR_ID@|$(MEMO_VENDOR_ID)|g' \
		-e 's|@MEMO_CODENAME@|$(MEMO_CODENAME)|g' \
		-e 's|@MEMO_TARGET@|$(MEMO_TARGET)|g' \
		-e 's|@MEMO_VERSION_STRING@|$(MEMO_VERSION_STRING)|g' \
		$(BUILD_MISC)/base-files/$$file > $(BUILD_WORK)/base-files/$$file; \
	done
	cp -a $(BUILD_WORK)/base-files/{host.conf,issue,issue.net} $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)/etc
	cp -a $(BUILD_WORK)/base-files/os-release $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_WORK)/base-files/procursus $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)/etc/dpkg/origins
	cp -a $(BUILD_WORK)/base-files/{motd,dot.bashrc,dot.profile,profile} $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/base-files
	cp -a $(BUILD_MISC)/base-files/{copyright,README,README.FHS,FAQ} $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc/os-release $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)/etc/os-release
	$(INSTALL) -m755 $(BUILD_MISC)/base-files/10-uname $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)/etc/update-motd.d
	zstd -c19 $(BUILD_MISC)/base-files/changelog > $(BUILD_STAGE)/base-files/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/changelog
endif

base-files-package: base-files
	# base-files.mk Package Structure
	rm -rf $(BUILD_DIST)/base-files

	# base-files.mk Prep base-files
	cp -af $(BUILD_STAGE)/base-files $(BUILD_DIST)

	# base-files.mk Make .debs
	$(call PACK,base-files,DEB_BASE-FILES_V)

	# base-files.mk Build cleanup
	rm -rf $(BUILD_DIST)/base-files

.PHONY: base-files base-files-package
