ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += doc-cmds
DOC-CMDS_VERSION := 55
DEB_DOC-CMDS_V   ?= $(DOC-CMDS_VERSION)

doc-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,doc_cmds,$(DOC-CMDS_VERSION),doc_cmds-$(DOC-CMDS_VERSION))
	$(call EXTRACT_TAR,doc_cmds-$(DOC-CMDS_VERSION).tar.gz,doc_cmds-doc_cmds-$(DOC-CMDS_VERSION),doc-cmds)
	mkdir -p $(BUILD_STAGE)/doc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/doc-cmds/.build_complete),)
doc-cmds:
	@echo "Using previously built doc-cmds."
else
doc-cmds: doc-cmds-setup
	mkdir -p $(BUILD_STAGE)/doc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1/}
	cd $(BUILD_WORK)/doc-cmds; \
	for bin in checknr colcrt; do \
		$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILD_STAGE)/doc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/$$bin.c; \
		$(INSTALL) -Dm644 $$bin/$$bin.1 $(BUILD_STAGE)/doc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/; \
	done; \
	$(INSTALL) -m644 intro.1 $(BUILD_STAGE)/doc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1;
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
