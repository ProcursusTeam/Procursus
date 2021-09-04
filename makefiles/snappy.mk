ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += snappy
SNAPPY_VERSION := 1.3
SNAPPY_COMMIT  := 9c97ea03d941c0fcedc762222dacc4ea7b57c403
DEB_SNAPPY_V   ?= $(SNAPPY_VERSION)

snappy-setup: setup
	$(call GITHUB_ARCHIVE,sbingner,snappy,$(SNAPPY_COMMIT),$(SNAPPY_COMMIT))
	$(call EXTRACT_TAR,snappy-$(SNAPPY_COMMIT).tar.gz,snappy-$(SNAPPY_COMMIT),snappy)
	mkdir -p $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib}

ifneq ($(wildcard $(BUILD_WORK)/snappy/.build_complete),)
snappy:
	@echo "Using previously built snappy."
else
snappy: snappy-setup
	cd $(BUILD_WORK)/snappy && \
	$(CC) $(CFLAGS) -c libsnappy.m -o libsnappy.m.o; \
	$(CC) $(CFLAGS) -c libsnappy.c -o libsnappy.c.o; \
	$(CC) $(CFLAGS) -c snappy.c -o snappy.o; \
	$(AR) -crs -- $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-sbingner.a libsnappy.{c,m}.o; \
	$(LD) $(LDFLAGS) -shared -framework IOKit -framework Foundation libsnappy.{c,m}.o -o $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-sbingner.1.dylib; \
	$(LN_S) $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-sbingner{.1,}.dylib; \
	$(LD) $(LDFLAGS) -L$(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lsnappy-sbingner -o $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/snappy
	$(call AFTER_BUILD,copy)
endif

snappy-package: snappy-stage
	# snappy.mk Package Structure
	rm -rf $(BUILD_DIST)/snappy
	
	# snappy.mk Prep snappy
	cp -a $(BUILD_STAGE)/snappy $(BUILD_DIST)
	
	# snappy.mk Sign
	$(call SIGN,snappy,general.xml)
	
	# snappy.mk Make .debs
	$(call PACK,snappy,DEB_SNAPPY_V)
	
	# snappy.mk Build cleanup
	rm -rf $(BUILD_DIST)/snappy

.PHONY: snappy snappy-package
