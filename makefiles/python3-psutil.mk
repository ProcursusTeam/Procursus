ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += python3-psutil
PYTHON3_PSUTIL_VERSION := 5.9.4
DEB_PYTHON3_PSUTIL_V   ?= $(PYTHON3_PSUTIL_VERSION)

python3-psutil-setup: setup
	$(call GITHUB_ARCHIVE,giampaolo,psutil,$(PYTHON3_PSUTIL_VERSION),release-$(PYTHON3_PSUTIL_VERSION),python3-psutil)
	$(call EXTRACT_TAR,python3-psutil-$(PYTHON3_PSUTIL_VERSION).tar.gz,psutil-release-$(PYTHON3_PSUTIL_VERSION),python3-psutil)

ifneq ($(wildcard $(BUILD_WORK)/python3-psutil/.build_complete),)
python3-psutil:
	@echo "Using previously built python3-psutil."
else
python3-psutil: python3-psutil-setup python3
	cd $(BUILD_WORK)/python3-psutil && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/python3-psutil" \
		--install-layout=deb
	find $(BUILD_STAGE)/python3-psutil -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

python3-psutil-package: python3-psutil-stage
	# python3-psutil.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-psutil

	# python3-psutil.mk Prep python3-psutil
	cp -a $(BUILD_STAGE)/python3-psutil $(BUILD_DIST)

	# python3-psutil.mk Sign
	$(call SIGN,python3-psutil,general.xml)

	# python3-psutil.mk Make .debs
	$(call PACK,python3-psutil,DEB_PYTHON3_PSUTIL_V)

	# python3-psutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-psutil

.PHONY: python3-psutil python3-psutil-package
