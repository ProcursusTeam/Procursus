ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += python3-glances
PYTHON3_GLANCES_VERSION := 3.1.7
DEB_PYTHON3_GLANCES_V   ?= $(PYTHON3_GLANCES_VERSION)

python3-glances-setup: setup
	$(call GITHUB_ARCHIVE,nicolargo,glances,$(PYTHON3_GLANCES_VERSION),v$(PYTHON3_GLANCES_VERSION))
	$(call EXTRACT_TAR,glances-$(PYTHON3_GLANCES_VERSION).tar.gz,glances-$(PYTHON3_GLANCES_VERSION),python3-glances)

ifneq ($(wildcard $(BUILD_WORK)/python3-glances/.build_complete),)
python3-glances:
	@echo "Using previously built python3-glances."
else
python3-glances: python3-glances-setup python3
	cd $(BUILD_WORK)/python3-glances && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/python3-glances" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/python3-glances -name __pycache__ -prune -exec rm -rf {} \;
	touch $(BUILD_WORK)/python3-glances/.build_complete
endif

python3-glances-package: python3-glances-stage
	# python3-glances.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-glances
	cp -a $(BUILD_STAGE)/python3-glances $(BUILD_DIST)

	# python3-glances.mk Sign
	$(call SIGN,python3-glances,general.xml)

	# python3-glances.mk Make .debs
	$(call PACK,python3-glances,DEB_PYTHON3_GLANCES_V)

	# python3-glances.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-glances

.PHONY: python3-glances python3-glances-package
