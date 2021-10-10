ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += ldid
# Saurik tagged 2.1.5, but sbingner hasn't pulled it yet so we apply the patches
LDID_VERSION     := 2.1.5
LDID_GIT_VERSION := 2.1.4+16.g5b8581c
DEB_LDID_V       ?= $(LDID_VERSION)-procursus

ldid-setup: setup
	$(call GITHUB_ARCHIVE,sbingner,ldid,$(LDID_GIT_VERSION),v$(LDID_GIT_VERSION))
	$(call EXTRACT_TAR,ldid-$(LDID_GIT_VERSION).tar.gz,ldid-$(subst +,-,$(LDID_GIT_VERSION)),ldid)
	$(call DO_PATCH,ldid,ldid,-p1)
	mkdir -p $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

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
