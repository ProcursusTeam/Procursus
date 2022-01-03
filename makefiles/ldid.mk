ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += ldid
LDID_VERSION := 2.1.5-procursus2
DEB_LDID_V   ?= $(LDID_VERSION)

ldid-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,ldid,$(LDID_VERSION),v$(LDID_VERSION))
	$(call EXTRACT_TAR,ldid-$(LDID_VERSION).tar.gz,ldid-$(LDID_VERSION),ldid)
	mkdir -p $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/{zh_TW,}/man1}

ifneq ($(wildcard $(BUILD_WORK)/ldid/.build_complete),)
ldid:
	@echo "Using previously built ldid."
else
ldid: ldid-setup openssl libplist
	$(CC) -c $(CFLAGS) -I$(BUILD_WORK)/ldid -o $(BUILD_WORK)/ldid/lookup2.o $(BUILD_WORK)/ldid/lookup2.c
	$(CXX) -std=c++11 $(CXXFLAGS) -I$(BUILD_WORK)/ldid -DLDID_VERSION=\"$(LDID_VERSION)\" \
		-o $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ldid \
		$(BUILD_WORK)/ldid/lookup2.o $(BUILD_WORK)/ldid/ldid.cpp \
		$(LDFLAGS) -lcrypto -lplist-2.0
	$(LN_S) ldid $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ldid2
	$(INSTALL) -m644 $(BUILD_WORK)/ldid/ldid.1 $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/ldid.1
	$(INSTALL) -m644 $(BUILD_WORK)/ldid/ldid.1.zh_TW $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/zh_TW/man1/ldid.1
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
