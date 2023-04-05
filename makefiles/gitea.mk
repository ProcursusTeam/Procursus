ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gitea
GITEA_VERSION := 1.18.5
DEB_GITEA_V   ?= $(GITEA_VERSION)

gitea-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/gitea-$(GITEA_VERSION).tar.gz, \
		https://github.com/go-gitea/gitea/releases/download/v$(GITEA_VERSION)/gitea-src-$(GITEA_VERSION).tar.gz)
	$(call EXTRACT_TAR,gitea-$(GITEA_VERSION).tar.gz,gitea-src-$(GITEA_VERSION),gitea)
	$(call DO_PATCH,gitea,gitea,-p1)

ifneq ($(wildcard $(BUILD_WORK)/gitea/.build_complete),)
gitea:
	@echo "Using previously built gitea."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
gitea: gitea-setup
else
gitea: gitea-setup openpam
endif
	cd $(BUILD_WORK)/gitea && go mod vendor
	+$(DEFAULT_GOLANG_FLAGS) TAGS="bindata pam sqlite sqlite_unlock_notify" \
		LDFLAGS="$(LDFLAGS) -Wl,-U,_pam_start_confdir" \
		$(MAKE) -C $(BUILD_WORK)/gitea build
	install -Dm755 $(BUILD_WORK)/gitea/gitea $(BUILD_STAGE)/gitea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gitea
	install -Dm755 $(BUILD_MISC)/gitea/gitea-wrapper \
		$(BUILD_STAGE)/gitea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gitea-wrapper
	install -Dm644 $(BUILD_MISC)/gitea/io.gitea.web.plist \
		$(BUILD_STAGE)/gitea/$(MEMO_PREFIX)/Library/LaunchDaemons/io.gitea.web.plist
	sed -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/gitea/$(MEMO_PREFIX)/Library/LaunchDaemons/io.gitea.web.plist \
		$(BUILD_STAGE)/gitea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gitea-wrapper
	install -Dm644 $(BUILD_WORK)/gitea/custom/conf/app.example.ini $(BUILD_STAGE)/gitea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gitea/app.example.ini
	touch $(BUILD_WORK)/gitea/.build_complete
endif

gitea-package: gitea-stage
	# gitea.mk Package Structure
	rm -rf $(BUILD_DIST)/gitea
	
	# gitea.mk Prep gitea
	cp -a $(BUILD_STAGE)/gitea $(BUILD_DIST)
	
	# gitea.mk Sign
	$(call SIGN,gitea,general.xml)
	
	# gitea.mk Make .debs
	$(call PACK,gitea,DEB_GITEA_V)
	
	# gitea.mk Build cleanup
	rm -rf $(BUILD_DIST)/gitea

.PHONY: gitea gitea-package
