ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += hstspreload
HSTSPRELOAD_VERSION := 20220710
DEB_HSTSPRELOAD_V   ?= $(HSTSPRELOAD_VERSION)

hstspreload-setup: setup
	mkdir -p $(BUILD_WORK)/hstspreload
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/hstspreload, \
		https://raw.githubusercontent.com/chromium/chromium/master/net/http/transport_security_state_static.json \
		https://gitlab.com/rockdaboot/libhsts/-/raw/master/src/hsts-make-dafsa)
	chmod 0755 $(BUILD_WORK)/hstspreload/hsts-make-dafsa
	sed -i 's/^ *\/\/.*$$//g' $(BUILD_WORK)/hstspreload/transport_security_state_static.json
	sed -i 's|env python|env python3|' $(BUILD_WORK)/hstspreload/hsts-make-dafsa

ifneq ($(wildcard $(BUILD_WORK)/hstspreload/.build_complete),)
hstspreload:
	@echo "Using previously built hstspreload."
else
hstspreload: hstspreload-setup
	mkdir -p $(BUILD_STAGE)/hstspreload/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/hstspreload
	$(BUILD_WORK)/hstspreload/hsts-make-dafsa --output-format=binary \
		"$(BUILD_WORK)/hstspreload/transport_security_state_static.json" \
		"$(BUILD_STAGE)/hstspreload/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/hstspreload/hsts.dafsa"
	$(call AFTER_BUILD)
endif

hstspreload-package: hstspreload-stage
	# hstspreload.mk Package Structure
	rm -rf $(BUILD_DIST)/hstspreload

	# hstspreload.mk Prep hstspreload
	cp -a $(BUILD_STAGE)/hstspreload $(BUILD_DIST)/hstspreload

	# hstspreload.mk Make .debs
	$(call PACK,hstspreload,DEB_HSTSPRELOAD_V)

	# hstspreload.mk Build cleanup
	rm -rf $(BUILD_DIST)/hstspreload

.PHONY: hstspreload hstspreload-package
