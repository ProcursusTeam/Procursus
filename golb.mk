ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += golb
# I'm not going to bump the version any higher than 1.0.1. Just change commit date/short hash.
GOLB_VERSION   := 1.0.1+git20201118.7ffffff
DEB_GOLB_V     ?= $(GOLB_VERSION)

GOLB_COMMIT    := 7ffffff5ec79e0ce4c26ef219c6b7c43891917e4

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
	$(CC) $(CFLAGS) \
		-framework IOKit \
		-framework CoreFoundation \
		-lcompression \
		$(BUILD_WORK)/golb/golb.c \
		$(BUILD_WORK)/golb/aes_ap.c \
		-o $(BUILD_STAGE)/golb/usr/bin/aes_ap
	$(CC) $(CFLAGS) \
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
