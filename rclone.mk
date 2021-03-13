ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += rclone
RCLONE_VERSION := 1.53.3
DEB_RCLONE_V   ?= $(RCLONE_VERSION)

rclone-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/rclone-$(RCLONE_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/rclone-$(RCLONE_VERSION).tar.gz \
			https://github.com/rclone/rclone/archive/v$(RCLONE_VERSION).tar.gz
	$(call EXTRACT_TAR,rclone-$(RCLONE_VERSION).tar.gz,rclone-$(RCLONE_VERSION),rclone)
	mkdir -p $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{bin,share/man/man1}

ifneq ($(MEMO_ARCH),arm64)
rclone:
	@echo "Unsupported target $(MEMO_TARGET)"
else ifneq ($(wildcard $(BUILD_WORK)/rclone/.build_complete),)
rclone:
	@echo "Using previously built rclone."
else
rclone: rclone-setup
	cd $(BUILD_WORK)/rclone && \
		GOARCH=arm64 \
		GOOS=darwin \
		CGO_CFLAGS="$(CFLAGS)" \
		CGO_CPPFLAGS="$(CPPFLAGS)" \
		CGO_LDFLAGS="$(LDFLAGS)" \
		CGO_ENABLED=1 \
		CC="$(CC)" \
		go build \
			--ldflags "-s -X github.com/rclone/rclone/fs.Version=$(RCLONE_VERSION)"
	cp -a $(BUILD_WORK)/rclone/rclone $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	cp -a $(BUILD_WORK)/rclone/rclone.1 $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man/man1
	touch $(BUILD_WORK)/rclone/.build_complete
endif

rclone-package: rclone-stage
	# rclone.mk Package Structure
	rm -rf $(BUILD_DIST)/rclone
	mkdir -p $(BUILD_DIST)/rclone/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)

	# rclone.mk Prep rclone
	cp -a $(BUILD_STAGE)/rclone/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{bin,share} $(BUILD_DIST)/rclone/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)

	# rclone.mk Sign
	$(call SIGN,rclone,general.xml)

	# rclone.mk Make .debs
	$(call PACK,rclone,DEB_RCLONE_V)

	# rclone.mk Build cleanup
	rm -rf $(BUILD_DIST)/rclone

.PHONY: rclone rclone-package
