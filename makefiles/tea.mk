ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tea
TEA_VERSION := 0.7.0
DEB_TEA_V   ?= $(TEA_VERSION)

tea-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/tea-$(TEA_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/tea-$(TEA_VERSION).tar.gz \
			https://gitea.com/gitea/tea/archive/v$(TEA_VERSION).tar.gz
	tar -xf $(BUILD_SOURCE)/tea-$(TEA_VERSION).tar.gz -C $(BUILD_WORK)

ifneq ($(wildcard $(BUILD_WORK)/tea/.build_complete),)
tea:
	@echo "Using previously built tea."
else
tea: tea-setup
	cd $(BUILD_WORK)/tea; $(DEFAULT_GOLANG_FLAGS) \
		go build -ldflags '-X "main.Version=$(DEB_TEA_V)"'
	$(INSTALL) -Dm755 $(BUILD_WORK)/tea/tea $(BUILD_STAGE)/tea/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tea
	touch $(BUILD_WORK)/tea/.build_complete
endif

tea-package: tea-stage
	# tea.mk Package Structure
	rm -rf $(BUILD_DIST)/tea
	
	# tea.mk Prep tea
	cp -a $(BUILD_STAGE)/tea $(BUILD_DIST)
	
	# tea.mk Sign
	$(call SIGN,tea,general.xml)
	
	# tea.mk Make .debs
	$(call PACK,tea,DEB_TEA_V)
	
	# tea.mk Build cleanup
	rm -rf $(BUILD_DIST)/tea

.PHONY: tea tea-package
