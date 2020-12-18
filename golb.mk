ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += golb
# I'm not going to bump the version any higher than 1.0.1. Just change commit date/short hash.
GOLB_COMMIT    := 7ffffff2bd24017b06d499f337f27ccab73129a1
GOLB_VERSION   := 1.0.1+git20201124.$(shell echo $(GOLB_COMMIT) | cut -c -7)
DEB_GOLB_V     ?= $(GOLB_VERSION)

golb-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/golb-v$(GOLB_COMMIT).tar.gz" ] \
		&& wget -nc -O$(BUILD_SOURCE)/golb-v$(GOLB_COMMIT).tar.gz \
			https://github.com/0x7ff/golb/archive/$(GOLB_COMMIT).tar.gz
	$(call EXTRACT_TAR,golb-v$(GOLB_COMMIT).tar.gz,golb-$(GOLB_COMMIT),golb)
	mkdir -p $(BUILD_STAGE)/golb/usr/bin

ifneq ($(wildcard $(BUILD_WORK)/golb/.build_complete),)
golb:
	@echo "Using previously built golb."
else
golb: golb-setup

	###
	# As of right now, -arch arm64e is prepended to the CFLAGS to allow for it to work properly on arm64e iPhones.
	# Do not compile this for <= 1600 with XCode 12, and do not compile it for >= 1700 with Xcode << 12.
	# 1.0.3+git20201124.7ffffff should be the last version (save for some emergency update) for CFVER <= 1600
	# To make toolchain switching easier on me, I'm just going to compile this for >= 1700 from now on.
	###

	$(CC) -arch arm64e $(CFLAGS) \
		-framework IOKit \
		-framework CoreFoundation \
		-lcompression \
		$(BUILD_WORK)/golb/golb.c \
		$(BUILD_WORK)/golb/aes_ap.c \
		-o $(BUILD_STAGE)/golb/usr/bin/aes_ap
	$(CC) -arch arm64e $(CFLAGS) \
		-framework IOKit \
		-framework CoreFoundation \
		-lcompression \
		$(BUILD_WORK)/golb/golb_ppl.c \
		$(BUILD_WORK)/golb/aes_ap.c \
		-o $(BUILD_STAGE)/golb/usr/bin/aes_ap_ppl
	touch $(BUILD_WORK)/golb/.build_complete
endif

golb-package: golb-stage
	# golb.mk Package Structure
	rm -rf $(BUILD_DIST)/golb
	mkdir -p $(BUILD_DIST)/golb
	
	# golb.mk Prep golb
	cp -a $(BUILD_STAGE)/golb/usr $(BUILD_DIST)/golb
	
	# golb.mk Sign
	$(call SIGN,golb,tfp0.xml)
	
	# golb.mk Make .debs
	$(call PACK,golb,DEB_GOLB_V)
	
	# golb.mk Build cleanup
	rm -rf $(BUILD_DIST)/golb

.PHONY: golb golb-package
