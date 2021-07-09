ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += darwintools
DARWINTOOLS_VERSION := 1.5
ZBRFIRMWARE_COMMIT  := 213f1051334fdf4e9e4989b8f55ef0714b6f2779
DEB_DARWINTOOLS_V   ?= $(DARWINTOOLS_VERSION)

darwintools-setup: setup
	$(call GITHUB_ARCHIVE,zbrateam,Firmware,$(ZBRFIRMWARE_COMMIT),$(ZBRFIRMWARE_COMMIT))
	$(call EXTRACT_TAR,Firmware-$(ZBRFIRMWARE_COMMIT).tar.gz,Firmware-$(ZBRFIRMWARE_COMMIT),darwintools)

ifneq ($(wildcard $(BUILD_WORK)/darwintools/.build_complete),)
darwintools:
	@echo "Using previously built darwintools."
else
darwintools: darwintools-setup
	+$(MAKE) -C $(BUILD_WORK)/darwintools all \
		FIRMWARE_MAINTAINER="$(DEB_MAINTAINER)" \
		PREFIX=$(MEMO_PREFIX) \
		EXECPREFIX=$(MEMO_SUB_PREFIX) \
		CFLAGS="$(CFLAGS)"
	$(INSTALL) -Dm 0755 $(BUILD_WORK)/darwintools/build/firmware $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/firmware
	$(INSTALL) -s -Dm 0755 $(BUILD_MISC)/darwintools/firmware-wrapper $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/firmware-wrapper
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/firmware-wrapper
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(CC) $(CFLAGS) $(BUILD_MISC)/darwintools/sw_vers.c -o $(BUILD_WORK)/darwintools/sw_vers -framework CoreFoundation -O3
	$(INSTALL) -s -Dm 0755 $(BUILD_WORK)/darwintools/sw_vers $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sw_vers
	$(INSTALL) -Dm 0644 $(BUILD_MISC)/darwintools/resolv.conf $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)/etc/resolv.conf
endif
	touch $(BUILD_WORK)/darwintools/.build_complete
endif

darwintools-package: darwintools-stage
	# darwintools.mk Package Structure
	rm -rf $(BUILD_DIST)/darwintools

	# darwintools.mk Prep darwintools
	cp -a $(BUILD_STAGE)/darwintools $(BUILD_DIST)

	# darwintools.mk Sign
	$(call SIGN,darwintools,general.xml)

	# darwintools.mk Make .debs
	$(call PACK,darwintools,DEB_DARWINTOOLS_V)

	# darwintools.mk Build cleanup
	rm -rf $(BUILD_DIST)/darwintools

.PHONY: darwintools darwintools-package
