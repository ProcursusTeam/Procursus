ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += attach
ATTACH_VERSION := 0.0.2
DEB_ATTACH_V   ?= $(ATTACH_VERSION)

attach-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/attach-$(ATTACH_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/attach-$(ATTACH_VERSION).tar.gz \
			https://github.com/NyaMisty/Attach-Detach/archive/$(ATTACH_VERSION).tar.gz
	$(call EXTRACT_TAR,attach-$(ATTACH_VERSION).tar.gz,attach-detach-$(ATTACH_VERSION),attach)
	mkdir -p $(BUILD_STAGE)/attach/usr/bin

ifneq ($(wildcard $(BUILD_WORK)/attach/.build_complete),)
attach:
	@echo "Using previously built attach."
else
attach: attach-setup
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/usr/bin/attach $(BUILD_WORK)/attach/attach.m $(LDFLAGS) -framework CoreFoundation -framework IOKit
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/usr/bin/detach $(BUILD_WORK)/attach/detach.c $(LDFLAGS) -framework CoreFoundation -framework IOKit
	touch $(BUILD_WORK)/attach/.build_complete
endif

attach-package: attach-stage
	# attach.mk Package Structure
	rm -rf $(BUILD_DIST)/attach
	mkdir -p $(BUILD_DIST)/attach
	
	# attach.mk Prep attach
	cp -a $(BUILD_STAGE)/attach/usr $(BUILD_DIST)/attach

	# attach.mk Sign
	$(call SIGN,attach,attach.xml)
	
	# attach.mk Make .debs
	$(call PACK,attach,DEB_ATTACH_V)
	
	# attach.mk Build cleanup
	rm -rf $(BUILD_DIST)/attach

.PHONY: attach attach-package
