ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xonsh
XONSH_COMMIT  := 86f02c034182e2c7211036f1bba0a460df909e77
XONSH_VERSION := 0.9.27+git20210624.$(shell echo $(XONSH_COMMIT) | cut -c -7)
DEB_XONSH_V   ?= $(XONSH_VERSION)

xonsh-setup: setup
	$(call GITHUB_ARCHIVE,xonsh,xonsh,$(XONSH_COMMIT),$(XONSH_COMMIT))
	$(call EXTRACT_TAR,xonsh-$(XONSH_COMMIT).tar.gz,xonsh-$(XONSH_COMMIT),xonsh)

ifneq ($(wildcard $(BUILD_WORK)/xonsh/.build_complete),)
xonsh:
	@echo "Using previously built xonsh."
else
xonsh: xonsh-setup python3-prompt-toolkit
	cd $(BUILD_WORK)/xonsh && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py install \
		--install-layout=deb \
		--root=$(BUILD_STAGE)/xonsh \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	$(SED) -i "s|$$(cat $(BUILD_STAGE)/xonsh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xonsh | grep \#! | sed 's/#!//')|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3|" $(BUILD_STAGE)/xonsh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	find $(BUILD_STAGE)/xonsh -name __pycache__ -prune -exec rm -rf {} \;
	touch $(BUILD_WORK)/xonsh/.build_complete
endif

xonsh-package: xonsh-stage
	# xonsh.mk Package Structure
	mkdir -p $(BUILD_DIST)/xonsh
	cp -a $(BUILD_STAGE)/xonsh $(BUILD_DIST)

	# xonsh.mk Sign
	$(call SIGN,xonsh,general.xml)

	# xonsh.mk Make .debs
	$(call PACK,xonsh,DEB_XONSH_V)

	# xonsh.mk Build Cleanup
	rm -rf $(BUILD_DIST)/xonsh

.PHONY: xonsh xonsh-package
