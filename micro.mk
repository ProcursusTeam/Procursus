ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += micro
MICRO_VERSION  := 2.0.8
DEB_MICRO_V    ?= $(MICRO_VERSION)

micro-setup: setup
	$(call GITHUB_ARCHIVE,zyedidia,micro,$(MICRO_VERSION),v$(MICRO_VERSION),micro)
	$(call EXTRACT_TAR,micro-$(MICRO_VERSION).tar.gz,micro-$(MICRO_VERSION),micro)
	mkdir -p $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifeq (,$(shell which go))
micro:
	@echo "go needs to be installed in order to compile micro. Please install go and try again."
else ifneq ($(wildcard $(BUILD_WORK)/micro/.build_complete),)
micro:
	@echo "Using previously built micro."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
micro: micro-setup
else
micro: micro-setup libiosexec
endif
	$(MAKE) -C $(BUILD_WORK)/micro build \
		$(DEFAULT_GOLANG_FLAGS)

	$(GINSTALL) -Dm755 $(BUILD_WORK)/micro/micro $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/micro
	$(GINSTALL) -Dm644 $(BUILD_WORK)/micro/assets/packaging/micro.1 $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/micro.1
	$(GINSTALL) -Dm644 $(BUILD_WORK)/micro/assets/packaging/micro.desktop $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/applications/micro.desktop
	touch $(BUILD_WORK)/micro/.build_complete

endif

micro-package: micro-stage
	# micro.mk Package Structure
	rm -rf $(BUILD_DIST)/micro
	mkdir -p $(BUILD_DIST)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# micro.mk Prep micro
	cp -a $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# micro.mk Sign
	$(call SIGN,micro,general.xml)

	# micro.mk Make .debs
	$(call PACK,micro,DEB_MICRO_V)

	# micro.mk Build cleanup
	rm -rf $(BUILD_DIST)/micro

.PHONY: micro micro-package
