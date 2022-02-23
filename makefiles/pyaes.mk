ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pyaes
PYAES_VERSION := 1.6.1
DEB_PYAES_V   ?= $(PYAES_VERSION)

pyaes-setup: setup
	$(call GITHUB_ARCHIVE,ricmoo,pyaes,$(PYAES_VERSION),v$(PYAES_VERSION))
	$(call EXTRACT_TAR,pyaes-$(PYAES_VERSION).tar.gz,pyaes-$(PYAES_VERSION),pyaes)

ifneq ($(wildcard $(BUILD_WORK)/pyaes/.build_complete),)
pyaes:
	@echo "Using previously built pyaes."
else
pyaes: pyaes-setup python3
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

pyaes-package: pyaes-stage
	# pyaes.mk Package Structure
	rm -rf $(BUILD_DIST)/pyaes

	# pyaes.mk Prep pyaes
	cp -a $(BUILD_STAGE)/pyaes $(BUILD_DIST)

	#pyaes.mk Make .debs
	$(call PACK,pyaes,DEB_PYAES_V)

	# pyaes.mk Build cleanup
	rm -rf $(BUILD_DIST)/pyaes

.PHONY: pyaes pyaes-package
