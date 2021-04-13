ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += xxhash
XXHASH_VERSION := 0.8.0
DEB_XXHASH_V   ?= $(XXHASH_VERSION)

xxhash-setup: setup
	$(call GITHUB_ARCHIVE,Cyan4973,xxhash,$(XXHASH_VERSION),v$(XXHASH_VERSION))
	$(call EXTRACT_TAR,xxhash-$(XXHASH_VERSION).tar.gz,xxHash-$(XXHASH_VERSION),xxhash)
	$(SED) -i 's/UNAME :=/UNAME ?=/' $(BUILD_WORK)/xxhash/Makefile

ifneq ($(wildcard $(BUILD_WORK)/xxhash/.build_complete),)
xxhash:
	@echo "Using previously built xxhash."
else
xxhash: xxhash-setup
	+$(MAKE) -C $(BUILD_WORK)/xxhash \
		UNAME=Darwin \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/xxhash install \
		UNAME=Darwin \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/xxhash
	+$(MAKE) -C $(BUILD_WORK)/xxhash install \
		UNAME=Darwin \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xxhash/.build_complete
endif

xxhash-package: xxhash-stage
	# xxhash.mk Package Structure
	rm -rf $(BUILD_DIST)/libxxhash{0,-dev} $(BUILD_DIST)/xxhash
	mkdir -p $(BUILD_DIST)/libxxhash{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/xxhash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xxhash.mk Prep xxhash
	cp -a $(BUILD_STAGE)/xxhash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/xxhash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xxhash.mk Prep libxxhash0
	cp -a $(BUILD_STAGE)/xxhash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxxhash.0*.dylib $(BUILD_DIST)/libxxhash0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xxhash.mk Prep libxxhash-dev
	cp -a $(BUILD_STAGE)/xxhash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libxxhash.0*.dylib) $(BUILD_DIST)/libxxhash-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xxhash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxxhash-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xxhash.mk Sign
	$(call SIGN,xxhash,general.xml)
	$(call SIGN,libxxhash0,general.xml)

	# xxhash.mk Make .debs
	$(call PACK,xxhash,DEB_XXHASH_V)
	$(call PACK,libxxhash0,DEB_XXHASH_V)
	$(call PACK,libxxhash-dev,DEB_XXHASH_V)

	# xxhash.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxxhash{0,-dev} $(BUILD_DIST)/xxhash

.PHONY: xxhash xxhash-package
