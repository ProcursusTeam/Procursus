ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS    += profile.d
PROFILED_VERSION := 0-7
DEB_PROFILED_V   ?= $(PROFILED_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/profile.d/.build_complete),)
profile.d:
	@echo "Using previously built profile.d."
else
profile.d:
	mkdir -p $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc/profile.d
	cp $(BUILD_INFO)/{,z}profile $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc
	cp $(BUILD_INFO)/terminal.sh $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc/profile.d
	touch $(BUILD_STAGE)/profile.d/.build_complete
endif

profile.d-package: profile.d-stage
	# profile.d.mk Package Structure
	rm -rf $(BUILD_DIST)/profile.d
	mkdir -p $(BUILD_DIST)/profile.d/$(MEMO_PREFIX)

	# profile.d.mk Prep profile.d
	cp -a $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc $(BUILD_DIST)/profile.d/$(MEMO_PREFIX)

	# profile.d.mk Permissions
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/profile.d/$(MEMO_PREFIX)/etc/profile.d/terminal.sh

	# profile.d.mk Make .debs
	$(call PACK,profile.d,DEB_PROFILED_V)

	# profile.d.mk Build cleanup
	rm -rf $(BUILD_DIST)/profile.d

.PHONY: profile.d profile.d-package

endif # ($(MEMO_TARGET),darwin-\*)
