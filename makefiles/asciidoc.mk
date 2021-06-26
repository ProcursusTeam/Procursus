ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += asciidoc
ASCIIDOC_VERSION := 9.1.0
DEB_ASCIIDOC_V   ?= $(ASCIIDOC_VERSION)

### Requires libxml2-utils to build

asciidoc-setup: setup
	$(call GITHUB_ARCHIVE,asciidoc-py,asciidoc-py,$(ASCIIDOC_VERSION),$(ASCIIDOC_VERSION))
	$(call EXTRACT_TAR,asciidoc-py-$(ASCIIDOC_VERSION).tar.gz,asciidoc-py-$(ASCIIDOC_VERSION),asciidoc)

ifneq ($(wildcard $(BUILD_WORK)/asciidoc/.build_complete),)
asciidoc:
	@echo "Using previously built asciidoc."
else
asciidoc: asciidoc-setup
	cd $(BUILD_WORK)/asciidoc && autoconf
	cd $(BUILD_WORK)/asciidoc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/asciidoc
	+$(MAKE) -C $(BUILD_WORK)/asciidoc install \
		DESTDIR=$(BUILD_STAGE)/asciidoc
	for file in $(BUILD_STAGE)/asciidoc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*.py; do \
		mv $$file $(BUILD_STAGE)/asciidoc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(basename $$file .py); \
	done
	$(SED) -i "s|$$(cat $(BUILD_STAGE)/asciidoc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/a2x | grep \#! | sed 's/#!//')|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3|" $(BUILD_STAGE)/asciidoc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	touch $(BUILD_WORK)/asciidoc/.build_complete
endif

asciidoc-package: asciidoc-stage
	# asciidoc.mk Package Structure
	rm -rf $(BUILD_DIST)/asciidoc
	
	# asciidoc.mk Prep asciidoc
	cp -a $(BUILD_STAGE)/asciidoc $(BUILD_DIST)
	
	# asciidoc.mk Sign
	$(call SIGN,asciidoc,general.xml)
	
	# asciidoc.mk Make .debs
	$(call PACK,asciidoc,DEB_ASCIIDOC_V)
	
	# asciidoc.mk Build cleanup
	rm -rf $(BUILD_DIST)/asciidoc

.PHONY: asciidoc asciidoc-package
