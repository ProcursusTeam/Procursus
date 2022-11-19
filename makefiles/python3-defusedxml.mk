ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                += python3-defusedxml
PYTHON3_DEFUSEDXML_VERSION := 0.7.1
DEB_PYTHON3_DEFUSEDXML_V   ?= $(PYTHON3_DEFUSEDXML_VERSION)

python3-defusedxml-setup: setup
	$(call GITHUB_ARCHIVE,tiran,defusedxml,$(PYTHON3_DEFUSEDXML_VERSION),v$(PYTHON3_DEFUSEDXML_VERSION),python3-defusedxml)
	$(call EXTRACT_TAR,python3-defusedxml-$(PYTHON3_DEFUSEDXML_VERSION).tar.gz,defusedxml-$(PYTHON3_DEFUSEDXML_VERSION),python3-defusedxml)

ifneq ($(wildcard $(BUILD_WORK)/python3-defusedxml/.build_complete),)
python3-defusedxml:
	@echo "Using previously built python3-defusedxml."
else
python3-defusedxml: python3-defusedxml-setup python3
	cd $(BUILD_WORK)/python3-defusedxml && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/python3-defusedxml" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/python3-defusedxml -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

python3-defusedxml-package: python3-defusedxml-stage
	# python3-defusedxml.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-defusedxml

	# python3-defusedxml.mk Prep python3-defusedxml
	cp -a $(BUILD_STAGE)/python3-defusedxml $(BUILD_DIST)

	#python3-defusedxml.mk Make .debs
	$(call PACK,python3-defusedxml,DEB_PYTHON3_DEFUSEDXML_V)

	# python3-defusedxml.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-defusedxml

.PHONY: python3-defusedxml python3-defusedxml-package
