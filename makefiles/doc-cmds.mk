ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += doc-cmds
DOC-CMDS_VERSION := 66
DEB_DOC-CMDS_V   ?= $(DOC-CMDS_VERSION)

doc-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,doc_cmds,$(DOC-CMDS_VERSION),doc_cmds-$(DOC-CMDS_VERSION))
	$(call EXTRACT_TAR,doc_cmds-$(DOC-CMDS_VERSION).tar.gz,doc_cmds-doc_cmds-$(DOC-CMDS_VERSION),doc-cmds)

ifneq ($(wildcard $(BUILD_WORK)/doc-cmds/.build_complete),)
doc-cmds:
	@echo "Using previously built doc-cmds."
else
doc-cmds: doc-cmds-setup
	mkdir -p $(BUILD_STAGE)/doc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	$(INSTALL) -m644 $(BUILD_WORK)/doc-cmds/intro.1 $(BUILD_STAGE)/doc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1;
	$(call AFTER_BUILD)
endif

doc-cmds-package: doc-cmds-stage
	# doc-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/doc-cmds

	# doc-cmds.mk Prep doc-cmds
	cp -a $(BUILD_STAGE)/doc-cmds $(BUILD_DIST)

	# doc-cmds.mk Sign
	$(call SIGN,doc-cmds,general.xml)

	# doc-cmds.mk Make .debs
	$(call PACK,doc-cmds,DEB_DOC-CMDS_V)

	# doc-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/doc-cmds

.PHONY: doc-cmds doc-cmds-package
