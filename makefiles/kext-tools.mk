ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS        += kext-tools
KEXT_TOOLS_VERSION := 692.100.6
DEB_KEXT_TOOLS_V   ?= $(KEXT_TOOLS_VERSION)

KEXT_TOOLS_CFLAGS := kext_tools_util.o Shims.o -framework IOKit -framework CoreFoundation -DPRIVATE -D__OS_EXPOSE_INTERNALS__ -DEMBEDDED_HOST

kext-tools-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://opensource.apple.com/tarballs/kext_tools/kext_tools-$(KEXT_TOOLS_VERSION).tar.gz
	$(call EXTRACT_TAR,kext_tools-$(KEXT_TOOLS_VERSION).tar.gz,kext_tools-$(KEXT_TOOLS_VERSION),kext-tools)
	$(call DO_PATCH,kext-tools,kext-tools,-p1)
	mkdir -p $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,share/man/man8}

ifneq ($(wildcard $(BUILD_WORK)/kext-tools/.build_complete),)
kext-tools:
	@echo "Using previously built kext-tools."
else
kext-tools: kext-tools-setup
	cd $(BUILD_WORK)/kext-tools && \
	$(CC) $(CFLAGS) -c kext_tools_util.c KernelManagementShims/Shims.m -DPRIVATE -D__OS_EXPOSE_INTERNALS__ -DEMBEDDED_HOST && echo kext_tools_util.o; \
	$(CC) $(CFLAGS) -c KernelManagementShims/Shims.m -DPRIVATE -D__OS_EXPOSE_INTERNALS__ -DEMBEDDED_HOST && echo Shims.o; \
	$(CC) $(CFLAGS) $(LDFLAGS) $(KEXT_TOOLS_CFLAGS) kextstat_main.c -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextstat && echo kextstat; \
	$(CC) $(CFLAGS) $(LDFLAGS) $(KEXT_TOOLS_CFLAGS) kextload_main.c -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextload && echo kextload; \
	$(CC) $(CFLAGS) $(LDFLAGS) $(KEXT_TOOLS_CFLAGS) kextfind_*.c QEQuery.c -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextfind && echo kextfind; \
	$(CC) $(CFLAGS) $(LDFLAGS) $(KEXT_TOOLS_CFLAGS) kextunload_main.c -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextunload && echo kextunload; \
	$(CC) $(CFLAGS) $(LDFLAGS) $(KEXT_TOOLS_CFLAGS) kextlibs_main.c -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextlibs && echo kextlibs; \
	$(CC) $(CFLAGS) $(LDFLAGS) $(KEXT_TOOLS_CFLAGS) mkext*.c -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/mkextunpack && echo mkextunpack;
	cp -a $(BUILD_WORK)/kext-tools/{kext{stat,find,libs,{un,}load},mkextunpack}.8 $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD)
endif

kext-tools-package: kext-tools-stage
	# kext-tools.mk Package Structure
	rm -rf $(BUILD_DIST)/kext-tools

	# kext-tools.mk Prep kext-tools
	cp -a $(BUILD_STAGE)/kext-tools $(BUILD_DIST)

	# kext-tools.mk Sign
	$(LDID) -S$(BUILD_MISC)/entitlements/general.xml $(BUILD_DIST)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/{mkextunpack,kext{libs,find}}
	$(LDID) -S$(BUILD_MISC)/entitlements/kextstat.plist $(BUILD_DIST)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextstat
	$(LDID) -S$(BUILD_MISC)/entitlements/kextload.plist $(BUILD_DIST)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kext{un,}load
	find $(BUILD_DIST)/kext-tools -name '.ldid*' -type f -delete

	# kext-tools.mk Make .debs
	$(call PACK,kext-tools,DEB_KEXT_TOOLS_V)

	# kext-tools.mk Build cleanup
	rm -rf $(BUILD_DIST)/kext-tools

.PHONY: kext-tools kext-tools-package

endif
