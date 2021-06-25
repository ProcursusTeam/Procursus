ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += argon2
ARGON2_VERSION := 20190702
DEB_ARGON2_V   ?= 0~$(ARGON2_VERSION)

argon2-setup: setup
	$(call GITHUB_ARCHIVE,P-H-C,phc-winner-argon2,$(ARGON2_VERSION),$(ARGON2_VERSION),argon2)
	$(call EXTRACT_TAR,argon2-$(ARGON2_VERSION).tar.gz,phc-winner-argon2-$(ARGON2_VERSION),argon2)
	$(call DO_PATCH,argon2,argon2,-p1)

ifneq ($(wildcard $(BUILD_WORK)/argon2/.build_complete),)
argon2:
	@echo "Using previously built argon2."
else
argon2: argon2-setup
	+$(MAKE) -C $(BUILD_WORK)/argon2 install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/argon2/ \
		KERNEL_NAME="Darwin" \
		OPTTARGET="aarch64"
	rm -f $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libargon2.dylib
	+$(MAKE) -C $(BUILD_WORK)/argon2/ install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_BASE) \
		KERNEL_NAME="Darwin" \
		OPTTARGET="aarch64"
	touch $(BUILD_WORK)/argon2/.build_complete
endif

argon2-package: argon2-stage
	# argon2.mk Package Structure
	rm -rf $(BUILD_DIST)/libargon2-{1,dev} $(BUILD_DIST)/argon2
	mkdir -p $(BUILD_DIST)/libargon2-{1,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/argon2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# argon2.mk Prep libargon2-1
	cp -a $(BUILD_STAGE)/argon2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libargon2.1.dylib $(BUILD_DIST)/libargon2-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# argon2.mk Prep libargon2-dev
	cp -a $(BUILD_STAGE)/argon2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libargon2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/argon2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libargon2.{a,dylib},pkgconfig} $(BUILD_DIST)/libargon2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# argon2.mk Prep argon2
	cp -a $(BUILD_STAGE)/argon2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/argon2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# argon2.mk Sign
	$(call SIGN,libargon2-1,general.xml)
	$(call SIGN,argon2,general.xml)

	# argon2.mk Make .debs
	$(call PACK,libargon2-1,DEB_ARGON2_V)
	$(call PACK,libargon2-dev,DEB_ARGON2_V)
	$(call PACK,argon2,DEB_ARGON2_V)

	# argon2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libargon2-{1,dev} $(BUILD_DIST)/argon2

.PHONY: argon2 argon2-package
