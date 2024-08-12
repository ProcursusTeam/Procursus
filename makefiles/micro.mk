ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += micro
MICRO_VERSION  := 2.0.13
DEB_MICRO_V    ?= $(MICRO_VERSION)

# NOTE: Generating syntax files for micro on an iOS host doesn't work
# NOTE: Make sure to clear Go's module cache (GOMODCACHE) after
# each build so that syntax highlighting works on supported targets

micro-setup: setup
	$(call GITHUB_ARCHIVE,zyedidia,micro,$(MICRO_VERSION),v$(MICRO_VERSION))
	$(call EXTRACT_TAR,micro-$(MICRO_VERSION).tar.gz,micro-$(MICRO_VERSION),micro)
	$(call DO_PATCH,micro,micro,-p1)
	mkdir -p $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/man/man1,bin}

ifneq ($(wildcard $(BUILD_WORK)/micro/.build_complete),)
micro:
	@echo "Using previously built micro."
else
micro: micro-setup
	$(MAKE) -C $(BUILD_WORK)/micro build \
		$(DEFAULT_GOLANG_FLAGS) \
		VERSION="$(MICRO_VERSION)" \
		DATE="Procursus"
	$(INSTALL) -Dm755 $(BUILD_WORK)/micro/micro $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(INSTALL) -Dm644 $(BUILD_WORK)/micro/assets/packaging/micro.1 $(BUILD_STAGE)/micro/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
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
