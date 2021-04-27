ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   	 		+= docbook
DOCBOOK_VERSION  		:= 5.1
STYLESHEETS_VERSION		:= 2020-06-03
DEB_DOCBOOK_V	 		?= $(DOCBOOK_VERSION)

docbook-setup: setup
	$(call GITHUB_ARCHIVE,docbook,xslt10-stylesheets,$(STYLESHEETS_VERSION),snapshot/$(STYLESHEETS_VERSION))
	$(call EXTRACT_TAR,xslt10-stylesheets-$(STYLESHEETS_VERSION).tar.gz,xslt10-stylesheets-snapshot-$(STYLESHEETS_VERSION),docbook/xslt10-stylesheets)

ifneq ($(wildcard $(BUILD_WORK)/docbook/.build_complete),)
docbook:
	@echo "Using previously built docbook."
else
docbook: docbook-setup
	# touch $(BUILD_WORK)/docbook/.build_complete
endif

docbook-package: docbook-stage
	# docbook.mk Package Structure
	rm -rf $(BUILD_DIST)/docbook

	# docbook.mk Prep docbook
	cp -a $(BUILD_STAGE)/docbook $(BUILD_DIST)

	# docbook.mk Make .debs
	$(call PACK,docbook,DEB_DOCBOOK_V)

	# docbook.mk Build cleanup
	rm -rf $(BUILD_DIST)/docbook

.PHONY: docbook docbook-package
