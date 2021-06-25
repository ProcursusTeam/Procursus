ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                    += python3-prompt-toolkit
PYTHON3-PROMPT-TOOLKIT_VERSION := 3.0.18
DEB_PYTHON3-PROMPT-TOOLKIT_V   ?= $(PYTHON3-PROMPT-TOOLKIT_VERSION)-1

python3-prompt-toolkit-setup: setup
	$(call GITHUB_ARCHIVE,prompt-toolkit,python-prompt-toolkit,$(PYTHON3-PROMPT-TOOLKIT_VERSION),$(PYTHON3-PROMPT-TOOLKIT_VERSION))
	$(call EXTRACT_TAR,python-prompt-toolkit-$(PYTHON3-PROMPT-TOOLKIT_VERSION).tar.gz,python-prompt-toolkit-$(PYTHON3-PROMPT-TOOLKIT_VERSION),python3-prompt-toolkit)

ifneq ($(wildcard $(BUILD_WORK)/python3-prompt-toolkit/.build_complete),)
python3-prompt-toolkit:
	@echo "Using previously built python-prompt-toolkit."
else
python3-prompt-toolkit: python3-prompt-toolkit-setup python3-wcwidth
	cd $(BUILD_WORK)/python3-prompt-toolkit && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py install \
		--install-layout=deb \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--root=$(BUILD_STAGE)/python3-prompt-toolkit
	find $(BUILD_STAGE)/python3-prompt-toolkit -name __pycache__ -prune -exec rm -rf {} \;
	touch $(BUILD_WORK)/python3-prompt-toolkit/.build_complete
endif

python3-prompt-toolkit-package: python3-prompt-toolkit-stage
	# python-prompt-toolkit.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-prompt-toolkit
	cp -a $(BUILD_STAGE)/python3-prompt-toolkit $(BUILD_DIST)

	# python-prompt-toolkit.mk Sign
	$(call SIGN,python3-prompt-toolkit,general.xml)

	# python-prompt-toolkit.mk Make .debs
	$(call PACK,python3-prompt-toolkit,DEB_PYTHON3-PROMPT-TOOLKIT_V)

	# python-prompt-toolkit.mk Build Cleanup
	rm -rf $(BUILD_DIST)/python3-prompt-toolkit

.PHONY: python3-prompt-toolkit python3-prompt-toolkit-package
