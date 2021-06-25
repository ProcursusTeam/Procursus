ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += python3-wcwidth
PYTHON3-WCWIDTH_VERSION := 0.2.5
DEB_PYTHON3-WCWIDTH_V   ?= $(PYTHON3-WCWIDTH_VERSION)

python3-wcwidth-setup: setup
	$(call GITHUB_ARCHIVE,jquast,wcwidth,$(PYTHON3-WCWIDTH_VERSION),$(PYTHON3-WCWIDTH_VERSION))
	$(call EXTRACT_TAR,wcwidth-$(PYTHON3-WCWIDTH_VERSION).tar.gz,wcwidth-$(PYTHON3-WCWIDTH_VERSION),python3-wcwidth)

ifneq ($(wildcard $(BUILD_WORK)/python3-wcwidth/.build_complete),)
python3-wcwidth:
	@echo "Using previously built python3-wcwidth."
else
python3-wcwidth: python3-wcwidth-setup python3
	cd $(BUILD_WORK)/python3-wcwidth && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py install \
		--install-layout=deb \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--root=$(BUILD_STAGE)/python3-wcwidth
	find $(BUILD_STAGE)/python3-wcwidth -name __pycache__ -prune -exec rm -rf {} \;
	touch $(BUILD_WORK)/python3-wcwidth/.build_complete
endif

python3-wcwidth-package: python3-wcwidth-stage
	# python3-wcwidth.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-wcwidth
	cp -a $(BUILD_STAGE)/python3-wcwidth $(BUILD_DIST)

	# python3-wcwidth.mk Sign, unsure if needed
	$(call SIGN,python3-wcwidth,general.xml)

	# python3-wcwidth.mk Make .debs
	$(call PACK,python3-wcwidth,DEB_PYTHON3-WCWIDTH_V)

	# python3-wcwidth.mk Build Cleanup
	rm -rf $(BUILD_DIST)/python3-wcwidth

.PHONY: python3-wcwidth python3-wcwidth-package
