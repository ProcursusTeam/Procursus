ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS        += notifyutil
NOTIFYUTIL_VERSION := 279.40.4
DEB_NOTIFYUTIL_V   ?= $(NOTIFYUTIL_VERSION)

notifyutil-setup: setup
	curl --silent -Z --create-dirs -C - --remote-name-all --output-dir $(BUILD_SOURCE) https://opensource.apple.com/tarballs/Libnotify/Libnotify-$(NOTIFYUTIL_VERSION).tar.gz
	$(call EXTRACT_TAR,Libnotify-$(NOTIFYUTIL_VERSION).tar.gz,Libnotify-$(NOTIFYUTIL_VERSION),notifyutil)
	$(call DO_PATCH,notifyutil,notifyutil,-p1)
	mkdir -p $(BUILD_STAGE)/notifyutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

ifneq ($(wildcard $(BUILD_WORK)/notifyutil/.build_complete),)
notifyutil:
	@echo "Using previously built notifyutil."
else
notifyutil: notifyutil-setup
	$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_WORK)/notifyutil/notifyutil/notifyutil.c \
		-o $(BUILD_STAGE)/notifyutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/notifyutil
	install -m644 $(BUILD_WORK)/notifyutil/notifyutil/notifyutil.1 \
		$(BUILD_STAGE)/notifyutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/notifyutil.1
	$(call AFTER_BUILD)
endif

notifyutil-package: notifyutil-stage
	# notifyutil.mk Package Structure
	rm -rf $(BUILD_DIST)/notifyutil

	# notifyutil.mk Prep notifyutil
	cp -a $(BUILD_STAGE)/notifyutil $(BUILD_DIST)

	# notifyutil.mk Sign
	$(call SIGN,notifyutil,notifyutil.xml)

	# notifyutil.mk Make .debs
	$(call PACK,notifyutil,DEB_NOTIFYUTIL_V)

	# notifyutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/notifyutil

.PHONY: notifyutil notifyutil-package

endif # ($(MEMO_TARGET),darwin-\*)
