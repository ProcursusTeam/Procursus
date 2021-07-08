ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += siguza-utils
# Don't change the version, just the date and git hash
SIGUZA-UTILS_COMMIT     := 8ce24f02ec14da12ec264084328c3e9b6c9c7603
SIGUZA-UTILS_VERSION    := 1.0+git20210501.$(shell echo $(SIGUZA-UTILS_COMMIT) | cut -c -7)
DEB_SIGUZA-UTILS_V      ?= $(SIGUZA-UTILS_VERSION)

siguza-utils-setup: setup
	$(call GITHUB_ARCHIVE,Siguza,misc,$(SIGUZA-UTILS_COMMIT),$(SIGUZA-UTILS_COMMIT),siguza-utils)
	$(call EXTRACT_TAR,siguza-utils-$(SIGUZA-UTILS_COMMIT).tar.gz,misc-$(SIGUZA-UTILS_COMMIT),siguza-utils)
	mkdir -p $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/siguza-utils/.build_complete),)
siguza-utils:
	@echo "Using previously built siguza-utils."
else
siguza-utils: siguza-utils-setup
	# Delete mesu, it's broken afaik
	rm -rf $(BUILD_WORK)/siguza-utils/mesu.c

	# Compile bindump.c
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/siguza-utils/bindump.c \
		-o $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/bindump $(LDFLAGS)

	# Compile clz.c
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/siguza-utils/clz.c \
		-o $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clz $(LDFLAGS)

	# Compile dsc_syms.c
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/siguza-utils/dsc_syms.c \
		-o $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dsc_syms $(LDFLAGS)

	# Compile rand.c
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/siguza-utils/rand.c \
		-o $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rand $(LDFLAGS)

	# Compile strerror.c
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/siguza-utils/strerror.c \
		-o $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/strerror $(LDFLAGS) -framework CoreFoundation -framework Security

	# Compile vmacho.c
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/siguza-utils/vmacho.c \
		-o $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vmacho $(LDFLAGS)

	# Compile xref.c
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/siguza-utils/xref.c \
		-o $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xref $(LDFLAGS)

	chmod +x $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/bindump
	chmod +x $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clz
	chmod +x $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dsc_syms
	chmod +x $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rand
	chmod +x $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/strerror
	chmod +x $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vmacho
	chmod +x $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xref
	touch $(BUILD_WORK)/siguza-utils/.build_complete
endif

siguza-utils-package: siguza-utils-stage
	# siguza-utils.mk Package Structure
	cp -a $(BUILD_STAGE)/siguza-utils $(BUILD_DIST)

	# siguza-utils.mk Sign
	$(call SIGN,siguza-utils,general.xml)

	# siguza-utils.mk Make .debs
	$(call PACK,siguza-utils,DEB_SIGUZA-UTILS_V)

	# siguza-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/siguza-utils

.PHONY: siguza-utils siguza-utils-package
