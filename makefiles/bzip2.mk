ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += bzip2
BZIP2_VERSION := 1.0.8
DEB_BZIP2_V   ?= $(BZIP2_VERSION)-1

bzip2-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://sourceware.org/pub/bzip2/bzip2-$(BZIP2_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,bzip2-$(BZIP2_VERSION).tar.gz)
	$(call EXTRACT_TAR,bzip2-$(BZIP2_VERSION).tar.gz,bzip2-$(BZIP2_VERSION),bzip2)
	mkdir -p $(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)/{bin,$(MEMO_SUB_PREFIX)/share}

ifneq ($(wildcard $(BUILD_WORK)/bzip2/.build_complete),)
bzip2:
	@echo "Using previously built bzip2."
else
bzip2: bzip2-setup
	+$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CC=$(CC) \
		AR=$(AR) \
		RANLIB=$(RANLIB) \
		CFLAGS="$(CFLAGS)"
	mv $(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/man $(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	rm -rf $(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include}
	cd $(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
	rm -f bz{cmp,egrep,fgrep,less}; \
	$(LN_S) bzdiff bzcmp; \
	$(LN_S) bzgrep bzegrep; \
	$(LN_S) bzgrep bzfgrep; \
	$(LN_S) bzmore bzless
ifneq ($(MEMO_SUB_PREFIX),)
	for bin in $(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		$(LN_S) ../$(MEMO_SUB_PREFIX)/bin/$$(basename $$bin) $(BUILD_STAGE)/bzip2/$(MEMO_PREFIX)/bin/$$(basename $$bin); \
	done
endif
	$(call AFTER_BUILD)
endif

bzip2-package: bzip2-stage
	# bzip2.mk Package Structure
	rm -rf $(BUILD_DIST)/bzip2
	mkdir -p $(BUILD_DIST)/bzip2

	# bzip2.mk Prep bzip2
	cp -a $(BUILD_STAGE)/bzip2 $(BUILD_DIST)

	# bzip2.mk Sign
	$(call SIGN,bzip2,general.xml)

	# bzip2.mk Make .debs
	$(call PACK,bzip2,DEB_BZIP2_V)

	# bzip2.mk Build cleanup
	rm -rf $(BUILD_DIST)/bzip2

.PHONY: bzip2 bzip2-package
