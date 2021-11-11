ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS        += kext-tools
KEXT_TOOLS_VERSION := 623.120.1
DEB_KEXT_TOOLS_V   ?= $(KEXT_TOOLS_VERSION)

KEXT_TOOLS_CFLAGS := kext_tools_util.o -framework IOKit -framework CoreFoundation -DPRIVATE -D__OS_EXPOSE_INTERNALS__ -DEMBEDDED_HOST -D__OS_TRACE_BASE_H__

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
	$(CC) $(CFLAGS) -c kext_tools_util.c  -DPRIVATE -D__OS_EXPOSE_INTERNALS__ -DEMBEDDED_HOST -D__OS_TRACE_BASE_H__ && echo kext_tools_util.o; \
	$(CC) $(CFLAGS) $(LDFLAGS) kextstat_main.c $(KEXT_TOOLS_CFLAGS) -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextstat && echo kextstat; \
	$(CC) $(CFLAGS) $(LDFLAGS) kextload_main.c $(KEXT_TOOLS_CFLAGS) -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextload && echo kextload; \
	$(CC) $(CFLAGS) $(LDFLAGS) kextfind_*.c QEQuery.c $(KEXT_TOOLS_CFLAGS) -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextfind && echo kextfind; \
	$(CC) $(CFLAGS) $(LDFLAGS) kextunload_main.c $(KEXT_TOOLS_CFLAGS) -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextunload && echo kextunload; \
	$(CC) $(CFLAGS) $(LDFLAGS) kextlibs_main.c $(KEXT_TOOLS_CFLAGS) -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextlibs && echo kextlibs; \
	$(CC) $(CFLAGS) $(LDFLAGS) mkext*.c adler32.c $(KEXT_TOOLS_CFLAGS) -o $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/mkextunpack && echo mkextunpack;
	cp -a $(BUILD_WORK)/kext-tools/{kext{stat,find,libs,{un,}load},mkextunpack}.8 $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD)
endif

kext-tools-package: kext-tools-stage
	# kext-tools.mk Package Structure
	rm -rf $(BUILD_DIST)/kext-tools

	# kext-tools.mk Prep kext-tools
	cp -a $(BUILD_STAGE)/kext-tools $(BUILD_DIST)

	# kext-tools.mk Sign
	$(LDID) -S$(BUILD_MISC)/entitlements/general.xml $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/{mkextunpack,kext{libs,find}}
	$(LDID) -S$(BUILD_MISC)/entitlements/kextstat.plist $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kextstat
	$(LDID) -S$(BUILD_MISC)/entitlements/kextload.plist $(BUILD_STAGE)/kext-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kext{un,}load

	# kext-tools.mk Make .debs
	$(call PACK,kext-tools,DEB_KEXT_TOOLS_V)

	# kext-tools.mk Build cleanup
	rm -rf $(BUILD_DIST)/kext-tools

.PHONY: kext-tools kext-tools-package

endif
