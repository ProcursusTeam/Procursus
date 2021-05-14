ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += thefuck
THEFUCK_VERSION := 3.30
DEB_THEFUCK_V   ?= $(THEFUCK_VERSION)

thefuck-setup: setup
	$(call GITHUB_ARCHIVE,nvbn,thefuck,$(THEFUCK_VERSION),$(THEFUCK_VERSION))
	$(call EXTRACT_TAR,thefuck-$(THEFUCK_VERSION).tar.gz,thefuck-$(THEFUCK_VERSION),thefuck)
#	$(call DO_PATCH,thefuck,thefuck,-p1)

ifneq ($(wildcard $(BUILD_WORK)/thefuck/.build_complete),)
thefuck:
	@echo "Using previously built thefuck."
else
thefuck: thefuck-setup
	cd $(BUILD_WORK)/thefuck && unset MACOSX_DEPLOYMENT_TARGET && python$(PYTHON3_MAJOR_V) ./setup.py \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/thefuck" \
		--install-layout=deb
	find $(BUILD_STAGE)/thefuck -name __pycache__ -delete
	touch $(BUILD_WORK)/thefuck/.build_complete
endif
thefuck-package: thefuck-stage
	# thefuck.mk Package Structure
	rm -rf $(BUILD_DIST)/thefuck

	# thefuck.mk Prep thefuck
	cp -a $(BUILD_STAGE)/thefuck $(BUILD_DIST)/

	#thefuck.mk Make .debs
	$(call PACK,thefuck,DEB_THEFUCK_V)

	# thefuck.mk Build cleanup
	rm -rf $(BUILD_DIST)/thefuck

.PHONY: thefuck thefuck-package
