ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xonsh
XONSH_VERSION := 0.9.27
DEB_XONSH_V   ?= $(XONSH_VERSION)

### TODO: prompt_toolkit dependency :)

xonsh-setup: setup
	# Download main branch instead of tag for 0.9.27
	# Versions were not changed before making the version tag.
	$(call GITHUB_ARCHIVE,xonsh,xonsh,$(XONSH_VERSION),main)
	$(call EXTRACT_TAR,xonsh-$(XONSH_VERSION).tar.gz,xonsh-main,xonsh)
	$(call DO_PATCH,xonsh,xonsh,-p1) # Remove next version.
	# Pre-prepare this directory ahead of time; reduces package size (?)
	mkdir -p $(BUILD_STAGE)/xonsh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/

ifneq ($(wildcard $(BUILD_WORK)/xonsh/.build_complete),)
xonsh:
	@echo "Using previously built xonsh."
else
xonsh: xonsh-setup python3
	cd $(BUILD_WORK)/xonsh && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py install \
		--root=$(BUILD_STAGE)/xonsh \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--install-layout=deb
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
