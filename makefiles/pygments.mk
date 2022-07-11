ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += pygments
PYGMENTS_VERSION := 2.11.2
DEB_PYGMENTS_V   ?= $(PYGMENTS_VERSION)

pygments-setup: setup
	-[ ! -f $(BUILD_SOURCE)/pygments-$(PYGMENTS_VERSION).tar.gz ] && \
		curl --silent -Z --create-dirs -C - --remote-name-all --output  $(BUILD_SOURCE)/pygments-$(PYGMENTS_VERSION).tar.gz \
			https://github.com/pygments/pygments/archive/refs/tags/$(PYGMENTS_VERSION).tar.gz
	$(call EXTRACT_TAR,pygments-$(PYGMENTS_VERSION).tar.gz,pygments-$(PYGMENTS_VERSION),pygments)

ifneq ($(wildcard $(BUILD_WORK)/pygments/.build_complete),)
pygments:
	@echo "Using previously built pygments."
else
pygments: pygments-setup python3
	cd $(BUILD_WORK)/pygments && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/pygments" \
		--install-layout=deb
	find $(BUILD_STAGE)/pygments -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif
pygments-package: pygments-stage
	# pygments.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-pygments

	# pygments.mk Prep pygments
	cp -a $(BUILD_STAGE)/pygments $(BUILD_DIST)/python3-pygments

	#pygments.mk Make .debs
	$(call PACK,python3-pygments,DEB_PYGMENTS_V)

	# pygments.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-pygments

.PHONY: pygments pygments-package
