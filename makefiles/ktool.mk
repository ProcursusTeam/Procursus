ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += ktool
KTOOL_VERSION  := 1.0.0
DEB_KTOOL_V    ?= $(KTOOL_VERSION)

ktool-setup: setup
	$(call GITHUB_ARCHIVE,cxnder,ktool,$(KTOOL_VERSION),$(KTOOL_VERSION))
	$(call EXTRACT_TAR,ktool-$(KTOOL_VERSION).tar.gz,ktool-$(KTOOL_VERSION),ktool)
	$(call DO_PATCH,ktool,ktool,-p1)

ifneq ($(wildcard $(BUILD_WORK)/ktool/.build_complete),)
ktool:
	@echo "Using previously built ktool."
else
ktool: ktool-setup python3-kimg4 python3-pyaes pygments python3
	cd $(BUILD_WORK)/ktool && $(DEFAULT_SETUP_PY_ENV) python3 ./.legacy_setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/ktool" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/ktool -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

ktool-package: ktool-stage
	# ktool.mk Package Structure
	rm -rf $(BUILD_DIST)/ktool

	# ktool.mk Prep ktool
	cp -a $(BUILD_STAGE)/ktool $(BUILD_DIST)

	# ktool.mk Sign
	$(call SIGN,ktool,general.xml)

	# ktool.mk Make .debs
	$(call PACK,ktool,DEB_KTOOL_V)

	# ktool.mk Build cleanup
	rm -rf $(BUILD_DIST)/ktool

.PHONY: ktool ktool-package
