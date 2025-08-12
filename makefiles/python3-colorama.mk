ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS		 += python3-colorama
PYTHON3-COLORAMA_VERSION := 0.4.4
DEB_PYTHON3-COLORAMA_V   ?= $(PYTHON3-COLORAMA_VERSION)

python3-colorama-setup: setup
	$(call GITHUB_ARCHIVE,tartley,colorama,$(PYTHON3-COLORAMA_VERSION),$(PYTHON3-COLORAMA_VERSION))
	$(call EXTRACT_TAR,colorama-$(PYTHON3-COLORAMA_VERSION).tar.gz,colorama-$(PYTHON3-COLORAMA_VERSION),python3-colorama)


ifneq ($(wildcard $(BUILD_WORK)/python3-colorama/.build_complete),)
python3-colorama:
	@echo "Using previously built python3-colorama."
else
python3-colorama: python3-colorama-setup
	cd $(BUILD_WORK)/python3-colorama && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/python3-colorama" \
		--install-layout=deb
	find $(BUILD_STAGE)/python3-colorama -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif
python3-colorama-package: python3-colorama-stage
	# python3-colorama.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-colorama

	# python3-colorama.mk Prep python3-colorama
	cp -a $(BUILD_STAGE)/python3-colorama $(BUILD_DIST)/

	#python3-colorama.mk Make .debs
	$(call PACK,python3-colorama,DEB_PYTHON3-COLORAMA_V)

	# python3-colorama.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-colorama

.PHONY: python3-colorama python3-colorama-package
