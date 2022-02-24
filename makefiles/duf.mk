ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += duf
DUF_VERSION  := 0.8.1
DEB_DUF_V    ?= $(DUF_VERSION)

duf-setup: setup
	$(call GITHUB_ARCHIVE,muesli,duf,$(DUF_VERSION),v$(DUF_VERSION))
	$(call EXTRACT_TAR,duf-$(DUF_VERSION).tar.gz,duf-$(DUF_VERSION),duf)
	mkdir -p $(BUILD_STAGE)/duf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/duf/.build_complete),)
duf:
	@echo "Using previously built duf."
else
duf: duf-setup
	cd $(BUILD_WORK)/duf && $(DEFAULT_GOLANG_FLAGS) go build \
			-o $(BUILD_WORK)/duf/duf
	$(INSTALL) -Dm755 $(BUILD_WORK)/duf/duf $(BUILD_STAGE)/duf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(call AFTER_BUILD)
endif

duf-package: duf-stage
	# duf.mk Package Structure
	rm -rf $(BUILD_DIST)/duf
	mkdir -p $(BUILD_DIST)

	# duf.mk Prep duf
	cp -a $(BUILD_STAGE)/duf $(BUILD_DIST)

	# duf.mk Sign
	$(call SIGN,duf,general.xml)

	# duf.mk Make .debs
	$(call PACK,duf,DEB_DUF_V)

	# duf.mk Build cleanup
	rm -rf $(BUILD_DIST)/duf

.PHONY: duf duf-package
