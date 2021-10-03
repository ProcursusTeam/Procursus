ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xonsh
XONSH_VERSION := 0.10.1
DEB_XONSH_V   ?= $(XONSH_VERSION)

xonsh-setup: setup
	$(call GITHUB_ARCHIVE,xonsh,xonsh,$(XONSH_VERSION),$(XONSH_VERSION))
	$(call EXTRACT_TAR,xonsh-$(XONSH_VERSION).tar.gz,xonsh-$(XONSH_VERSION),xonsh)

ifneq ($(wildcard $(BUILD_WORK)/xonsh/.build_complete),)
xonsh:
	@echo "Using previously built xonsh."
else
xonsh: xonsh-setup python3-prompt-toolkit
	cd $(BUILD_WORK)/xonsh && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py install \
		--install-layout=deb \
		--root=$(BUILD_STAGE)/xonsh \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	sed -i "s|$$(cat $(BUILD_STAGE)/xonsh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xonsh | grep \#! | sed 's/#!//')|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3|" $(BUILD_STAGE)/xonsh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	find $(BUILD_STAGE)/xonsh -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
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
