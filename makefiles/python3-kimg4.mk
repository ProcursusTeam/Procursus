ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += pythnon3-kimg4
PYTHON3_KIMG4_VERSION := 0.1.1
PYTHON3_KIMG4_COMMIT  := 2e117290a90fbd53a4f5c4a8b60f8e32e6af0ad8
DEB_PYTHON3_KIMG4_V   ?= $(PYTHON3_KIMG4_VERSION)

python3-kimg4-setup: setup
	$(call GITHUB_ARCHIVE,cxnder,kimg4,$(PYTHON3_KIMG4_VERSION),$(PYTHON3_KIMG4_COMMIT))
	$(call EXTRACT_TAR,kimg4-$(PYTHON3_KIMG4_VERSION).tar.gz,kimg4-$(PYTHON3_KIMG4_COMMIT),python3-kimg4)

ifneq ($(wildcard $(BUILD_WORK)/python3-kimg4/.build_complete),)
python3-kimg4:
	@echo "Using previously built python3-kimg4."
else
python3-kimg4: python3-kimg4-setup python3-pyaes python3
	cd $(BUILD_WORK)/python3-kimg4 && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/python3-kimg4" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/python3-kimg4 -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

python3-kimg4-package: python3-kimg4-stage
	# python3-kimg4.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-kimg4

	# kimg4.mk Prep python3-kimg4
	cp -a $(BUILD_STAGE)/python3-kimg4 $(BUILD_DIST)

	# python3-kimg4.mk Make .debs
	$(call PACK,python3-kimg4,DEB_PYTHON3_KIMG4_V)

	# kimg4.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-kimg4

.PHONY: python3-kimg4 python3-kimg4-package
