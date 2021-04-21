ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += po4a
PO4A_VERSION := 0.63
DEB_PO4A_V   ?= $(PO4A_VERSION)

po4a-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/mquinson/po4a/releases/download/v$(PO4A_VERSION)/po4a-$(PO4A_VERSION).tar.gz
	$(call EXTRACT_TAR,po4a-$(PO4A_VERSION).tar.gz,po4a-$(PO4A_VERSION),po4a)

ifneq ($(wildcard $(BUILD_WORK)/po4a/.build_complete),)
po4a:
	@echo "Using previously built po4a."
else
po4a: po4a-setup perl
	cd $(BUILD_WORK)/po4a && /opt/procursus/bin/perl Build.PL \
		$(DEFAULT_PERL_BUILD_FLAGS)
	$(BUILD_WORK)/po4a/Build
	$(BUILD_WORK)/po4a/Build install
	rm -rf $(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/po4a/.build_complete
endif

po4a-package: po4a-stage
	# po4a.mk Package Structure
	rm -rf $(BUILD_DIST)/po4a

	# po4a.mk Prep po4a
	cp -a $(BUILD_STAGE)/po4a $(BUILD_DIST)

	# po4a.mk Make .debs
	$(call PACK,po4a,DEB_PO4A_V)

	# po4a.mk Build cleanup
	rm -rf $(BUILD_DIST)/po4a

.PHONY: po4a po4a-package
