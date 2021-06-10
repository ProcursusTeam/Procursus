ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pyyaml
PYYAML_VERSION := 5.4.1.1
DEB_PYYAML_V   ?= $(PYYAML_VERSION)

pyyaml-setup: setup
	$(call GITHUB_ARCHIVE,yaml,pyyaml,$(PYYAML_VERSION),$(PYYAML_VERSION))
	$(call EXTRACT_TAR,pyyaml-$(PYYAML_VERSION).tar.gz,pyyaml-$(PYYAML_VERSION),pyyaml)

ifneq ($(wildcard $(BUILD_WORK)/pyyaml/.build_complete),)
pyyaml:
	@echo "Using previously built pyyaml."
else
pyyaml: pyyaml-setup libyaml python3
	cd $(BUILD_WORK)/pyyaml && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		--with-libyaml \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/pyyaml" \
		--install-layout=deb
	find $(BUILD_STAGE)/pyyaml -name __pycache__ -prune -exec rm -rf {} \;
	touch $(BUILD_WORK)/pyyaml/.build_complete
endif
pyyaml-package: pyyaml-stage
	# pyyaml.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-yaml
	mkdir -p $(BUILD_DIST)/python3-yaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pyyaml.mk Prep python3-yaml
	cp -a $(BUILD_STAGE)/pyyaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/python3-yaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pyyaml.mk Sign
	$(call SIGN,python3-yaml,general.xml)

	#pyyaml.mk Make .debs
	$(call PACK,python3-yaml,DEB_PYYAML_V)

	# pyyaml.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-yaml

.PHONY: pyyaml pyyaml-package