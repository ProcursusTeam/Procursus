ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += npm
NPM_VERSION := 6.14.8
DEB_NPM_V   ?= $(NPM_VERSION)

npm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://registry.npmjs.org/npm/-/npm-$(NPM_VERSION).tgz
	$(call EXTRACT_TAR,npm-$(NPM_VERSION).tgz,package,npm)

ifneq ($(wildcard $(BUILD_WORK)/npm/.build_complete),)
npm:
	@echo "Using previously built npm."
else
npm: npm-setup
	mkdir -p $(BUILD_STAGE)/npm/{etc,usr/share}
	cp -a $(BUILD_WORK)/npm $(BUILD_STAGE)/npm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	node $(BUILD_WORK)/npm/bin/npm-cli.js install \
		-ddd --global \
		--prefix="$(BUILD_STAGE)/npm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		$(BUILD_STAGE)/npm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/npm
	@echo "# DO NOT MODIFY THIS FILE - use /etc/npmrc instead.\n\
globalconfig=$(MEMO_PREFIX)/etc/npmrc\n\
globalignorefile=$(MEMO_PREFIX)/etc/npmignore\n\
prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)\n" > $(BUILD_STAGE)/npm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/node_modules/npm/npmrc
	cp -a $(BUILD_WORK)/npm/package.json $(BUILD_STAGE)/npm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/npm
	touch $(BUILD_STAGE)/npm/etc/npmrc
	mkdir -p $(BUILD_STAGE)/npm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/nodejs
	ln -s ../npm $(BUILD_STAGE)/npm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/nodejs/npm
	touch $(BUILD_WORK)/npm/.build_complete
endif

npm-package: npm-stage
	# npm.mk Package Structure
	rm -rf $(BUILD_DIST)/npm
	mkdir -p $(BUILD_DIST)/npm

	# npm.mk Prep npm
	cp -a $(BUILD_STAGE)/npm $(BUILD_DIST)

	# npm.mk Make .debs
	$(call PACK,npm,DEB_NPM_V)

	# npm.mk Build cleanup
	rm -rf $(BUILD_DIST)/npm

.PHONY: npm npm-package
