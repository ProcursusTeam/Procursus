ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += rclone
RCLONE_VERSION := 1.55.0
DEB_RCLONE_V   ?= $(RCLONE_VERSION)

rclone-setup: setup
	$(call GITHUB_ARCHIVE,rclone,rclone,$(RCLONE_VERSION),v$(RCLONE_VERSION))
	$(call EXTRACT_TAR,rclone-$(RCLONE_VERSION).tar.gz,rclone-$(RCLONE_VERSION),rclone)
	mkdir -p $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

ifneq ($(wildcard $(BUILD_WORK)/rclone/.build_complete),)
rclone:
	@echo "Using previously built rclone."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
rclone: rclone-setup
else
rclone: rclone-setup libiosexec
endif
	cd $(BUILD_WORK)/rclone && \
		$(DEFAULT_GOLANG_FLAGS) \
		go build \
			--ldflags "-s -X github.com/rclone/rclone/fs.Version=$(RCLONE_VERSION)"
	cp -a $(BUILD_WORK)/rclone/rclone $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/rclone/rclone.1 $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	touch $(BUILD_WORK)/rclone/.build_complete
endif

rclone-package: rclone-stage
	# rclone.mk Package Structure
	rm -rf $(BUILD_DIST)/rclone
	mkdir -p $(BUILD_DIST)/rclone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rclone.mk Prep rclone
	cp -a $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/rclone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rclone.mk Sign
	$(call SIGN,rclone,general.xml)

	# rclone.mk Make .debs
	$(call PACK,rclone,DEB_RCLONE_V)

	# rclone.mk Build cleanup
	rm -rf $(BUILD_DIST)/rclone

.PHONY: rclone rclone-package
