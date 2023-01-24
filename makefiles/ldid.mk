ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += ldid
LDID_VERSION := 2.1.5-procursus7
DEB_LDID_V   ?= $(LDID_VERSION)

ldid-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,ldid,$(LDID_VERSION),v$(LDID_VERSION))
	$(call EXTRACT_TAR,ldid-$(LDID_VERSION).tar.gz,ldid-$(LDID_VERSION),ldid)

ifneq ($(wildcard $(BUILD_WORK)/ldid/.build_complete),)
ldid:
	@echo "Using previously built ldid."
else
ldid: ldid-setup openssl libplist
	+$(MAKE) -C $(BUILD_WORK)/ldid install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		VERSION="$(LDID_VERSION)" \
		DESTDIR="$(BUILD_STAGE)/ldid" \
		LIBPLIST_INCLUDES="-I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		LIBPLIST_LIBS="-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lplist-2.0" \
		LIBCRYPTO_INCLUDES="-I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		LIBCRYPTO_LIBS="-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lcrypto"
	install -d $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/
	install -m644 $(BUILD_WORK)/ldid/_ldid $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_ldid
	$(call AFTER_BUILD)
endif

ldid-package: ldid-stage
	# ldid.mk Package Structure
	rm -rf $(BUILD_DIST)/ldid

	# ldid.mk Prep ldid
	cp -a $(BUILD_STAGE)/ldid $(BUILD_DIST)

	# ldid.mk Sign
	$(call SIGN,ldid,general.xml)

	# ldid.mk Make .debs
	$(call PACK,ldid,DEB_LDID_V)

	# ldid.mk Build cleanup
	rm -rf $(BUILD_DIST)/ldid

.PHONY: ldid ldid-package
