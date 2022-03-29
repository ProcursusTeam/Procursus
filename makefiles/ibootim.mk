ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += ibootim
IBOOTIM_COMMIT  := 63138198d36acfddddff0d79869c2755e6c6b18c
IBOOTIM_VERSION := 1.0+git20190220.$(shell echo $(IBOOTIM_COMMIT) | cut -c -7)
DEB_IBOOTIM_V   ?= $(IBOOTIM_VERSION)

ibootim-setup: setup
	$(call GITHUB_ARCHIVE,realnp,ibootim,$(IBOOTIM_COMMIT),$(IBOOTIM_COMMIT),ibootim)
	$(call EXTRACT_TAR,ibootim-$(IBOOTIM_COMMIT).tar.gz,ibootim-$(IBOOTIM_COMMIT),ibootim)
	mkdir -p $(BUILD_STAGE)/ibootim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/ibootim/.build_complete),)
ibootim:
	@echo "Using previously built ibootim."
else
ibootim: ibootim-setup
	+$(MAKE) -C $(BUILD_WORK)/ibootim \
		CFLAGS="$(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	$(INSTALL) -m755 $(BUILD_WORK)/ibootim/ibootim $(BUILD_STAGE)/ibootim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ibootim
	$(call AFTER_BUILD)
endif

ibootim-package: ibootim-stage
	# ibootim.mk Package Structure
	rm -rf $(BUILD_DIST)/ibootim

	# ibootim.mk Prep ibootim
	cp -a $(BUILD_STAGE)/ibootim $(BUILD_DIST)

	# ibootim.mk Sign
	$(call SIGN,ibootim,general.xml)

	# ibootim.mk Make .debs
	$(call PACK,ibootim,DEB_IBOOTIM_V)

	# ibootim.mk Build cleanup
	rm -rf $(BUILD_DIST)/ibootim

.PHONY: ibootim ibootim-package
