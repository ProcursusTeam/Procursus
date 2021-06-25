ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += pygments
PYGMENTS_VERSION := 2.9.0
DEB_PYGMENTS_V   ?= $(PYGMENTS_VERSION)

pygments-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://files.pythonhosted.org/packages/ba/6e/7a7c13c21d8a4a7f82ccbfe257a045890d4dbf18c023f985f565f97393e3/Pygments-$(PYGMENTS_VERSION).tar.gz
	$(call EXTRACT_TAR,Pygments-$(PYGMENTS_VERSION).tar.gz,Pygments-$(PYGMENTS_VERSION),pygments)

ifneq ($(wildcard $(BUILD_WORK)/pygments/.build_complete),)
pygments:
	@echo "Using previously built pygments."
else
pygments: pygments-setup
	cd $(BUILD_WORK)/pygments && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/pygments" \
		--install-layout=deb
	find $(BUILD_STAGE)/pygments -name __pycache__ -prune -exec rm -rf {} \;
	touch $(BUILD_WORK)/pygments/.build_complete
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
