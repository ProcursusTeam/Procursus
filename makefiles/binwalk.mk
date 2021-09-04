ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += binwalk
BINWALK_VERSION := 2.3.2
DEB_BINWALK_V   ?= $(BINWALK_VERSION)

binwalk-setup: setup
	$(call GITHUB_ARCHIVE,ReFirmLabs,binwalk,$(BINWALK_VERSION),v$(BINWALK_VERSION))
	$(call EXTRACT_TAR,binwalk-$(BINWALK_VERSION).tar.gz,binwalk-$(BINWALK_VERSION),binwalk)

ifneq ($(wildcard $(BUILD_WORK)/binwalk/.build_complete),)
binwalk:
	@echo "Using previously built binwalk."
else
binwalk: binwalk-setup
	cd $(BUILD_WORK)/binwalk && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/binwalk" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/binwalk -name __pycache__ -prune -exec rm -rf {} \;
	install -Dm644 $(BUILD_MISC)/binwalk/binwalk.1 $(BUILD_STAGE)/binwalk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/binwalk.1
	$(call AFTER_BUILD)
endif

binwalk-package: binwalk-stage
	# binwalk.mk Package Structure
	rm -rf $(BUILD_DIST)/{python3-,}binwalk
	mkdir -p $(BUILD_DIST)/{python3-,}binwalk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	# binwalk.mk Prep binwalk
	cp -a $(BUILD_STAGE)/binwalk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/binwalk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	# binwalk.mk Prep python3-binwalk
	cp -a $(BUILD_STAGE)/binwalk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/python3-binwalk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	#binwalk.mk Make .debs
	$(call PACK,binwalk,DEB_BINWALK_V)
	$(call PACK,python3-binwalk,DEB_BINWALK_V)
	
	# binwalk.mk Build cleanup
	rm -rf $(BUILD_DIST)/{python3-,}binwalk

.PHONY: binwalk binwalk-package
