ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += python3-pyaes
PYTHON3_PYAES_VERSION := 1.6.1
DEB_PYTHON3_PYAES_V   ?= $(PYTHON3_PYAES_VERSION)

python3-pyaes-setup: setup
	$(call GITHUB_ARCHIVE,ricmoo,pyaes,$(PYTHON3_PYAES_VERSION),v$(PYTHON3_PYAES_VERSION))
	$(call EXTRACT_TAR,pyaes-$(PYTHON3_PYAES_VERSION).tar.gz,pyaes-$(PYTHON3_PYAES_VERSION),pyaes)

ifneq ($(wildcard $(BUILD_WORK)/pyaes/.build_complete),)
python3-pyaes:
	@echo "Using previously built pyaes."
else
python3-pyaes: python3-pyaes-setup
	cd $(BUILD_WORK)/pyaes && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/pyaes" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/pyaes -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

python3-pyaes-package: python3-pyaes-stage
	# pyaes.mk Package Structure
	rm -rf $(BUILD_DIST)/pyaes

	# pyaes.mk Prep pyaes
	cp -a $(BUILD_STAGE)/pyaes $(BUILD_DIST)

	#pyaes.mk Make .debs
	$(call PACK,python3-pyaes,DEB_PYTHON3_PYAES_V)

	# pyaes.mk Build cleanup
	rm -rf $(BUILD_DIST)/pyaes

.PHONY: python3-pyaes python3-pyaes-package
