ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += wtfutil
WTFUTIL_VERSION := 0.36.0
DEB_WTFUTIL_V   ?= $(WTFUTIL_VERSION)

wtfutil-setup: setup
	$(call GITHUB_ARCHIVE,wtfutil,wtf,$(WTFUTIL_VERSION),v$(WTFUTIL_VERSION))
	$(call EXTRACT_TAR,wtf-$(WTFUTIL_VERSION).tar.gz,wtf-$(WTFUTIL_VERSION),wtfutil)

ifneq ($(wildcard $(BUILD_WORK)/wtfutil/.build_complete),)
wtfutil:
	@echo "Using previously built wtfutil."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
wtfutil: wtfutil-setup
else
wtfutil: wtfutil-setup libiosexec
endif
	cd $(BUILD_WORK)/wtfutil && \
		$(DEFAULT_GOLANG_FLAGS) \
		go build -trimpath \
			--ldflags "-s -w -X main.version=$(WTFUTIL_VERSION) -X main.date=$$(date +%Y-%m-%dT%H:%M:%S%z)" \
			-o $(BUILD_STAGE)/wtfutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/wtfutil
	touch $(BUILD_WORK)/wtfutil/.build_complete
endif

wtfutil-package: wtfutil-stage
	# wtfutil.mk Package Structure
	rm -rf $(BUILD_DIST)/wtfutil

	# wtfutil.mk Prep wtfutil
	cp -a $(BUILD_STAGE)/wtfutil $(BUILD_DIST)

	# wtfutil.mk Sign
	$(call SIGN,wtfutil,general.xml)

	# wtfutil.mk Make .debs
	$(call PACK,wtfutil,DEB_WTFUTIL_V)

	# wtfutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/wtfutil

.PHONY: wtfutil wtfutil-package
