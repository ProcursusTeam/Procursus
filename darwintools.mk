ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += darwintools
DARWINTOOLS_VERSION := 1.3
ZBRFIRMWARE_COMMIT  := 09e2673391e03a0405838f7ebdf02fa1020c88fd
DEB_DARWINTOOLS_V   ?= $(DARWINTOOLS_VERSION)-2

darwintools-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/Firmware-$(ZBRFIRMWARE_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/Firmware-$(ZBRFIRMWARE_COMMIT).tar.gz \
			https://github.com/zbrateam/Firmware/archive/$(ZBRFIRMWARE_COMMIT).tar.gz
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
	$(GINSTALL) -Dm 0755 $(BUILD_WORK)/darwintools/build/firmware $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/firmware
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(CC) $(CFLAGS) $(BUILD_INFO)/sw_vers.c -o $(BUILD_WORK)/darwintools/sw_vers -framework CoreFoundation -O3
	$(GINSTALL) -s --strip-program=$(STRIP) -Dm 0755 $(BUILD_WORK)/darwintools/sw_vers $(BUILD_STAGE)/darwintools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sw_vers
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
