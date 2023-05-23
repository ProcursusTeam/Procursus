ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += unzip
UNZIP_VERSION  := 6.0
DEBIAN_UNZIP_V := $(UNZIP_VERSION)-28
DEB_UNZIP_V    ?= $(DEBIAN_UNZIP_V)

unzip-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://deb.debian.org/debian/pool/main/u/unzip/{unzip_$(UNZIP_VERSION).orig.tar.gz$(comma)unzip_$(DEBIAN_UNZIP_V).debian.tar.xz})
	$(call EXTRACT_TAR,unzip_$(UNZIP_VERSION).orig.tar.gz,unzip60,unzip)
	$(call EXTRACT_TAR,unzip_$(DEBIAN_UNZIP_V).debian.tar.xz,debian/patches,$(BUILD_PATCH)/unzip-$(UNZIP_VERSION))
	rm -rf $(BUILD_WORK)/debian $(BUILD_PATCH)/unzip-$(UNZIP_VERSION)/series
	$(call DO_PATCH,unzip-$(UNZIP_VERSION),unzip,-p1)
	rm -rf $(BUILD_PATCH)/unzip-$(UNZIP_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/unzip/.build_complete),)
unzip:
	@echo "Using previously built unzip."
else
unzip: unzip-setup
	$(MAKE) -C $(BUILD_WORK)/unzip -f unix/Makefile unzips \
		CC=$(CC) \
		CF='$(CFLAGS) -Wall -I. -DBSD -DUNIX -DACORN_FTYPE_NFS -DWILD_STOP_AT_DIR \
		-DLARGE_FILE_SUPPORT -DUNICODE_SUPPORT -DUNICODE_WCHAR -DUTF8_MAYBE_NATIVE \
		-DNO_LCHMOD -DDATE_FORMAT=DF_YMD -DUSE_BZIP2 -DIZ_HAVE_UXUIDGID ' \
		LF2="$(CFLAGS)" L_BZ2=-lbz2
	$(MAKE) -C $(BUILD_WORK)/unzip -f unix/Makefile install \
		prefix=$(BUILD_STAGE)/unzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		MANDIR="$(BUILD_STAGE)/unzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/"
	$(call AFTER_BUILD)
endif

unzip-package: unzip-stage
	# unzip.mk Package Structure
	rm -rf $(BUILD_DIST)/unzip
	mkdir -p $(BUILD_DIST)/unzip

	# unzip.mk Prep unzip
	cp -a $(BUILD_STAGE)/unzip $(BUILD_DIST)

	# unzip.mk Sign
	$(call SIGN,unzip,general.xml)

	# unzip.mk Make .debs
	$(call PACK,unzip,DEB_UNZIP_V)

	# unzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/unzip

.PHONY: unzip unzip-package
