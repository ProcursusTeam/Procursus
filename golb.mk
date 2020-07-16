ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += golb
GOLB_VERSION   := 1.0
DEB_GOLB_V     ?= $(GOLB_VERSION)

golb-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/golb-$(GOLB_VERSION).tar.gz" ] \
		&& wget -nc -O$(BUILD_SOURCE)/golb-$(GOLB_VERSION).tar.gz \
			https://github.com/ProcursusTeam/golb/archive/$(GOLB_VERSION).tar.gz
	$(call EXTRACT_TAR,golb-$(GOLB_VERSION).tar.gz,golb-$(GOLB_VERSION),golb)

ifneq ($(wildcard $(BUILD_WORK)/golb/.build_complete),)
golb:
	@echo "Using previously built golb."
else
golb: golb-setup
	cd $(BUILD_WORK)/golb
	mkdir -p $(BUILD_STAGE)/golb/usr/bin
	$(CC) $(CFLAGS) \
		-framework CoreFoundation \
		-framework IOKit \
		-lcompression \
		$(BUILD_WORK)/golb/key_dumper.c \
		-o $(BUILD_STAGE)/golb/usr/bin/key_dumper
	$(CC) $(CFLAGS) \
		-framework CoreFoundation \
		-lcompression \
		$(BUILD_WORK)/golb/golb.c \
		$(BUILD_WORK)/golb/aes_ap.c \
		-o $(BUILD_STAGE)/golb/usr/bin/aes_ap
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
