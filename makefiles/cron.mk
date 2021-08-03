ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS  += cron
CRON_VERSION := 40
DEB_CRON_V   ?= $(CRON_VERSION)

cron-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://opensource.apple.com/tarballs/cron/cron-$(CRON_VERSION).tar.gz
	$(call EXTRACT_TAR,cron-$(CRON_VERSION).tar.gz,cron-$(CRON_VERSION),cron)
	$(call DO_PATCH,cron,cron,-p1)
	mkdir -p $(BUILD_STAGE)/cron/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{s,}bin \
		$(BUILD_STAGE)/cron/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{1,5,8} \
		$(BUILD_STAGE)/cron/$(MEMO_PREFIX)/Library/LaunchDaemons \
		$(BUILD_STAGE)/cron/$(MEMO_PREFIX)/etc/

ifneq ($(wildcard $(BUILD_WORK)/cron/.build_complete),)
cron:
	@echo "Using previously built cron."
else
cron: cron-setup
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_WORK)/cron/cron/pathnames.h \
		$(BUILD_WORK)/cron/cron/config.h
	+$(BMAKE) -C $(BUILD_WORK)/cron \
		$(DEFAULT_BMAKE_FLAGS)
	+$(BMAKE) -C $(BUILD_WORK)/cron install \
		$(DEFAULT_BMAKE_FLAGS) \
		DESTDIR=$(BUILD_STAGE)/cron
	gzip -d $(BUILD_STAGE)/cron/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man*/*.gz
	$(SED) -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_WORK)/cron/com.vix.cron.plist > $(BUILD_STAGE)/cron/$(MEMO_PREFIX)/Library/LaunchDaemons/com.vix.cron.plist
	$(INSTALL) -Dm755 $(BUILD_MISC)/cron/cron-wrapper $(BUILD_STAGE)/cron/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/cron-wrapper
	cp -a $(BUILD_WORK)/cron/crontab.default $(BUILD_STAGE)/cron/$(MEMO_PREFIX)/etc/crontab
	$(call AFTER_BUILD)
endif

cron-package: cron-stage
	# cron.mk Package Structure
	rm -rf $(BUILD_DIST)/cron
	
	# cron.mk Prep cron
	cp -a $(BUILD_STAGE)/cron $(BUILD_DIST)
	
	# cron.mk Sign
	$(call SIGN,cron,general.xml)
	
	# cron.mk Make .debs
	$(call PACK,cron,DEB_CRON_V)
	
	# cron.mk Build cleanup
	rm -rf $(BUILD_DIST)/cron

.PHONY: cron cron-package

endif # ($(MEMO_TARGET),darwin-\*)
