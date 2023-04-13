ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += pongoterm
PONGOTERM_VERSION := 2022.12.21
PONGOOS_COMMIT    := d9a74407ef5774979d6c26dbe3f94f25a8408328
DEB_PONGOTERM_V   ?= $(PONGOTERM_VERSION)

pongoterm-setup: setup
	$(call GITHUB_ARCHIVE,checkra1n,pongoOS,$(PONGOOS_COMMIT),$(PONGOOS_COMMIT))
	$(call EXTRACT_TAR,pongoOS-$(PONGOOS_COMMIT).tar.gz,pongoOS-$(PONGOOS_COMMIT),pongoterm)
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/pongoterm/scripts,https://github.com/apple-oss-distributions/Libc/raw/Libc-997.90.3/gen/wordexp.c)
	sed 's|__OSX_AVAILABLE_STARTING|;//|g' $(TARGET_SYSROOT)/usr/include/wordexp.h > $(BUILD_WORK)/pongoterm/scripts/wordexp.h
	sed -i 's/<wordexp.h>/"wordexp.h"/g' $(BUILD_WORK)/pongoterm/scripts/{pongoterm,wordexp}.c
	mkdir -p $(BUILD_STAGE)/pongoterm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/pongoterm/.build_complete),)
pongoterm:
	@echo "Using previously built pongoterm."
else
pongoterm: pongoterm-setup
	$(CC) $(CFLAGS) -x objective-c $(BUILD_WORK)/pongoterm/scripts/pongoterm.c -c \
		-o $(BUILD_WORK)/pongoterm/scripts/pongoterm.o -D__kernel_ptr_semantics=""
	$(CC) $(CFLAGS) $(BUILD_WORK)/pongoterm/scripts/wordexp.c -c \
		-o $(BUILD_WORK)/pongoterm/scripts/wordexp.o
	$(CC) $(LDFLAGS) $(BUILD_WORK)/pongoterm/scripts/{pongoterm,wordexp}.o \
		-framework IOKit -framework Foundation -framework CoreFoundation \
		-o $(BUILD_STAGE)/pongoterm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pongoterm
	$(call AFTER_BUILD)
endif

pongoterm-package: pongoterm-stage
	# pongoterm.mk Package Structure
	rm -rf $(BUILD_DIST)/pongoterm

	# pongoterm.mk Prep pongoterm
	cp -a $(BUILD_STAGE)/pongoterm $(BUILD_DIST)

	# pongoterm.mk Sign
	$(call SIGN,pongoterm,usb.xml)

	# pongoterm.mk Make .debs
	$(call PACK,pongoterm,DEB_PONGOTERM_V)

	# pongoterm.mk Build cleanup
	rm -rf $(BUILD_DIST)/pongoterm

.PHONY: pongoterm pongoterm-package
