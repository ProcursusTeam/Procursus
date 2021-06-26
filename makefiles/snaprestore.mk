ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS         += snaprestore
SNAPRESTORE_VERSION := 0.3
DEB_SNAPRESTORE_V   ?= $(SNAPRESTORE_VERSION)

snaprestore-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://git.cameronkatri.com/snaprestore/snapshot/snaprestore-$(SNAPRESTORE_VERSION).tar.zst
	$(call EXTRACT_TAR,snaprestore-$(SNAPRESTORE_VERSION).tar.zst,snaprestore-$(SNAPRESTORE_VERSION),snaprestore)

ifneq ($(wildcard $(BUILD_WORK)/snaprestore/.build_complete),)
snaprestore:
	@echo "Using previously built snaprestore."
else
snaprestore: snaprestore-setup
	$(MAKE) -C $(BUILD_WORK)/snaprestore
	$(MAKE) -C $(BUILD_WORK)/snaprestore install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/snaprestore"
	touch $(BUILD_WORK)/snaprestore/.build_complete
endif

snaprestore-package: snaprestore-stage
	# snaprestore.mk Package Structure
	rm -rf $(BUILD_DIST)/snaprestore

	# snaprestore.mk Prep snaprestore
	cp -a $(BUILD_STAGE)/snaprestore $(BUILD_DIST)

	# snaprestore.mk Sign
	$(call SIGN,snaprestore,snaprestore.xml)

	# snaprestore.mk Make .debs
	$(call PACK,snaprestore,DEB_SNAPRESTORE_V)

	# snaprestore.mk Build cleanup
	rm -rf $(BUILD_DIST)/snaprestore

.PHONY: snaprestore snaprestore-package

endif
