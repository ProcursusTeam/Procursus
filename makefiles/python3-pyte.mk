ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += python3-pyte
PYTHON3-PYTE_VERSION := 0.8.0
DEB_PYTHON3-PYTE_V   ?= $(PYTHON3-PYTE_VERSION)

python3-pyte-setup: setup
	$(call GITHUB_ARCHIVE,selectel,pyte,$(PYTHON3-PYTE_VERSION),$(PYTHON3-PYTE_VERSION))
	$(call EXTRACT_TAR,pyte-$(PYTHON3-PYTE_VERSION).tar.gz,pyte-$(PYTHON3-PYTE_VERSION),python3-pyte)

ifneq ($(wildcard $(BUILD_WORK)/python3-pyte/.build_complete),)
python3-pyte:
	@echo "Using previously built python3-pyte."
else
python3-pyte: python3-pyte-setup
	cd $(BUILD_WORK)/python3-pyte && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/python3-pyte" \
		--install-layout=deb
	find $(BUILD_STAGE)/python3-pyte -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

python3-pyte-package: python3-pyte-stage
	# python3-pyte.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-pyte
	mkdir -p $(BUILD_DIST)/python3-pyte/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# python3-pyte.mk Prep python3-pyte
	cp -a $(BUILD_STAGE)/python3-pyte$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/python3-pyte/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# python3-pyte.mk Sign
	$(call SIGN,python3-pyte,general.xml)

	# python3-pyte.mk Make .debs
	$(call PACK,python3-pyte,DEB_PYTHON3-PYTE_V)

	# python3-pyte.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-pyte

.PHONY: python3-pyte python3-pyte-package
