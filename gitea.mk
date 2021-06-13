ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gitea
GITEA_VERSION := 1.14.2
DEB_GITEA_V   ?= $(GITEA_VERSION)

gitea-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/gitea-$(GITEA_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/gitea-$(GITEA_VERSION).tar.gz \
			https://github.com/go-gitea/gitea/releases/download/v$(GITEA_VERSION)/gitea-src-$(GITEA_VERSION).tar.gz
	-[ ! -f "$(BUILD_WORK)/gitea" ] && \
		mkdir -p $(BUILD_WORK)/gitea && \
			tar xf $(BUILD_SOURCE)/gitea-$(GITEA_VERSION).tar.gz -C $(BUILD_WORK)/gitea
	$(call DO_PATCH,gitea,gitea,-p1)
	$(SED) -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $(BUILD_WORK)/gitea/Makefile
	$(SED) -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $(BUILD_WORK)/gitea/custom/conf/app.example.ini

ifneq ($(wildcard $(BUILD_WORK)/gitea/.build_complete),)
gitea:
	@echo "Using previously built gitea."
else
gitea: gitea-setup
	cd $(BUILD_WORK)/gitea && go mod vendor
	+TAGS="bindata pam sqlite sqlite_unlock_notify" \
		$(MAKE) -C $(BUILD_WORK)/gitea build \
		$(DEFAULT_GOLANG_FLAGS)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/gitea/gitea $(BUILD_STAGE)/gitea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gitea
	$(GINSTALL) -Dm755 $(BUILD_MISC)/gitea/gitea-wrapper \
		$(BUILD_STAGE)/gitea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gitea-wrapper
	$(GINSTALL) -Dm644 $(BUILD_MISC)/gitea/io.gitea.web.plist \
		$(BUILD_STAGE)/gitea/$(MEMO_PREFIX)/Library/LaunchDaemons/io.gitea.web.plist
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/gitea/$(MEMO_PREFIX)/Library/LaunchDaemons/io.gitea.web.plist
	$(GINSTALL) -Dm644 $(BUILD_WORK)/gitea/custom/conf/app.example.ini $(BUILD_STAGE)/gitea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gitea/app.example.ini
	$(GINSTALL) -Dm660 $(BUILD_WORK)/gitea/custom/conf/app.example.ini $(BUILD_STAGE)/gitea/$(MEMO_PREFIX)/etc/gitea.ini
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
