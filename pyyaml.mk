ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pyyaml
PYYAML_VERSION := 5.4.1.1
DEB_PYYAML_V   ?= $(PYYAML_VERSION)

pyyaml-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/pyyaml-$(PYYAML_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/pyyaml-$(PYYAML_VERSION).tar.gz \
			https://github.com/yaml/pyyaml/archive/$(PYYAML_VERSION).tar.gz
	$(call EXTRACT_TAR,pyyaml-$(PYYAML_VERSION).tar.gz,pyyaml-$(PYYAML_VERSION),pyyaml)

ifneq ($(wildcard $(BUILD_WORK)/pyyaml/.build_complete),)
pyyaml:
	@echo "Using previously built pyyaml."
else
pyyaml: pyyaml-setup libyaml
	cd $(BUILD_WORK)/pyyaml && unset MACOSX_DEPLOYMENT_TARGET && python$(PYTHON3_MAJOR_V) ./setup.py \
		--with-libyaml \
		install \
		--prefix="/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/pyyaml"
	rm -rf $(BUILD_STAGE)/pyyaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/site-packages/yaml/__pycache__
	mv $(BUILD_STAGE)/pyyaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/site-packages/PyYAML-5.3.1-py$(PYTHON3_MAJOR_V).egg-info \
		$(BUILD_STAGE)/pyyaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/site-packages/PyYAML-5.3.1.egg-info
	touch $(BUILD_WORK)/pyyaml/.build_complete
endif
pyyaml-package: pyyaml-stage
	# pyyaml.mk Package Structure
	rm -rf $(BUILD_DIST)/python3-yaml
	mkdir -p $(BUILD_DIST)/python3-yaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages

	# pyyaml.mk Prep python3-yaml
	cp -a $(BUILD_STAGE)/pyyaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/site-packages/* $(BUILD_DIST)/python3-yaml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages

	# pyyaml.mk Sign
	$(call SIGN,python3-yaml,general.xml)

	#pyyaml.mk Make .debs
	$(call PACK,python3-yaml,DEB_PYYAML_V)

	# pyyaml.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3-yaml

.PHONY: pyyaml pyyaml-package
