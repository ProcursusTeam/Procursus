ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += ldid
LDID_COMMIT   := 2edb2a9307f1bd3909dadc20e80857c6e40c00c5
LDID_VERSION  := 2.1.4
#LDID_VERSION  := 2.1.2+20210222.$(shell echo $(LDID_COMMIT) | cut -c -7)
DEB_LDID_V    ?= $(LDID_VERSION)

ldid-setup: setup
	$(call GITHUB_ARCHIVE,Diatrus,saurik-ldid,$(LDID_COMMIT),$(LDID_COMMIT))
	$(call EXTRACT_TAR,saurik-ldid-$(LDID_COMMIT).tar.gz,saurik-ldid-$(LDID_COMMIT),ldid)
	mkdir -p $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/ldid/.build_complete),)
ldid:
	@echo "Using previously built ldid."
else
ldid: ldid-setup openssl libplist
	$(CC) -c $(CFLAGS) $(LDFLAGS) -o $(BUILD_WORK)/ldid/lookup2.o $(BUILD_WORK)/ldid/lookup2.c -I$(BUILD_WORK)/ldid
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -std=c++11 -o $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ldid $(BUILD_WORK)/ldid/lookup2.o $(BUILD_WORK)/ldid/ldid.cpp -I$(BUILD_WORK)/ldid -framework CoreFoundation -framework Security -lcrypto -lplist-2.0 -lxml2
	$(LN) -s ldid $(BUILD_STAGE)/ldid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ldid2
	touch $(BUILD_WORK)/ldid/.build_complete
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
