ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tbd
TBD_VERSION  := 2.2
DEB_TBD_V    ?= $(TBD_VERSION)

tbd-setup: setup
	$(call GITHUB_ARCHIVE,inoahdev,tbd,$(TBD_VERSION),$(TBD_VERSION))
	$(call EXTRACT_TAR,tbd-$(TBD_VERSION).tar.gz,tbd-$(TBD_VERSION),tbd)
	mkdir -p $(BUILD_STAGE)/tbd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/tbd/.build_complete),)
tbd:
	@echo "Using previously built tbd."
else
tbd: tbd-setup
	+$(MAKE) -C $(BUILD_WORK)/tbd CC="$(CC) $(CFLAGS) -Iinclude -std=gnu11"
	install -Dm755 $(BUILD_WORK)/tbd/bin/tbd $(BUILD_STAGE)/tbd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/tbd/.build_complete
endif

tbd-package: tbd-stage
	# tbd.mk package structure
	rm -rf $(BUILD_DIST)/tbd
	mkdir -p $(BUILD_DIST)/tbd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# tbd.mk prep tbd
	cp -a $(BUILD_STAGE)/tbd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tbd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# tbd.mk Sign
	$(call SIGN,tbd,general.xml)

	# TBD.mk Make .debs
	$(call PACK,tbd,DEB_TBD_V)

	# TBD.mk Build cleanup
	rm -rf $(BUILD_DIST)/tbd

.PHONY: tbd tbd-package
