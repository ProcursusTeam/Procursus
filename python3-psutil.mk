ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += python3-psutil
PYTHON3-PSUTIL_VERSION := 5.8.0
DEB_PYTHON3-PSUTIL_V   ?= $(PYTHON3-PSUTIL_VERSION)

python3-psutil-setup: setup
	wget -q -nc -P $(BUILD_SOURCE)  https://github.com/giampaolo/psutil/archive/refs/tags/release-$(PYTHON3-PSUTIL_VERSION).tar.gz
	$(call EXTRACT_TAR,release-$(PYTHON3-PSUTIL_VERSION).tar.gz,psutil-release-$(PYTHON3-PSUTIL_VERSION),python3-psutil)

ifneq ($(wildcard $(BUILD_WORK)/python3-psutil/.build_complete),)
python3-psutil:
	@echo "Using previously built python3-psutil."
else
python3-psutil: python3-psutil-setup python3
	cd $(BUILD_WORK)/python3-psutil && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/python3-psutil" \
		--install-layout=deb
	find $(BUILD_STAGE)/python3-psutil -name __pycache__ -prune -exec rm -rf {} \;
	touch $(BUILD_WORK)/python3-psutil/.build_complete
endif

python3-psutil-package: python3-psutil-stage
	# python3-psutil.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-psutil
	mkdir -p $(BUILD_DIST)/python3-psutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# python3-psutil.mk Prep python3-psutil
	cp -a $(BUILD_STAGE)/python3-psutil$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/python3-psutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# python3-psutil.mk Sign
	$(call SIGN,python3-psutil,general.xml)

	# python3-psutil.mk Make .debs
	$(call PACK,python3-psutil,DEB_PYTHON3-PSUTIL_V)

	# python3-psutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-psutil

.PHONY: python3-psutil python3-psutil-package
