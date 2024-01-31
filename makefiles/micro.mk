ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += micro
MICRO_VERSION  := 2.0.11
DEB_MICRO_V    ?= $(MICRO_VERSION)

micro-setup: setup
	$(call GIT_CLONE,https://github.com/zyedidia/micro.git,v$(MICRO_VERSION),micro)
	mkdir -p $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/micro/.build_complete),)
micro:
	@echo "Using previously built micro."
else
micro: micro-setup
	$(MAKE) -C $(BUILD_WORK)/micro build \
		$(DEFAULT_GOLANG_FLAGS) \
		VERSION="$(DEB_MICRO_V)" \
		DATE="$(shell date '+%B%e, %Y')"
	$(INSTALL) -Dm755 $(BUILD_WORK)/micro/micro $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/micro
	$(INSTALL) -Dm644 $(BUILD_WORK)/micro/assets/packaging/micro.1 $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/micro.1
	$(INSTALL) -Dm644 $(BUILD_WORK)/micro/assets/packaging/micro.desktop $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/applications/micro.desktop
	$(call AFTER_BUILD)
endif

micro-package: micro-stage
	# micro.mk Package Structure
	rm -rf $(BUILD_DIST)/micro

	# micro.mk Prep micro
	cp -a $(BUILD_STAGE)/micro $(BUILD_DIST)

	# micro.mk Sign
	$(call SIGN,micro,general.xml)

	# micro.mk Make .debs
	$(call PACK,micro,DEB_MICRO_V)

	# micro.mk Build cleanup
	rm -rf $(BUILD_DIST)/micro

.PHONY: micro micro-package
