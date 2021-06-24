ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS        += libucontext
LIBUCONTEXT_COMMIT := 455ecd495f706d5b57be3ff5b572c120c2a7a5a2

libucontext-setup: setup
	$(call GITHUB_ARCHIVE,utmapp,libucontext,$(LIBUCONTEXT_COMMIT),$(LIBUCONTEXT_COMMIT))
	$(call EXTRACT_TAR,libucontext-$(LIBUCONTEXT_COMMIT).tar.gz,libucontext-$(LIBUCONTEXT_COMMIT),libucontext)

ifneq ($(wildcard $(BUILD_WORK)/libucontext/.build_complete),)
libucontext:
	@echo "Using previously built libucontext."
else
libucontext: libucontext-setup
	+$(MAKE) -C $(BUILD_WORK)/libucontext all \
		ARCH=aarch64
	mkdir -p $(BUILD_STAGE)/libucontext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_WORK)/libucontext/libucontext.a $(BUILD_STAGE)/libucontext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_WORK)/libucontext/include $(BUILD_STAGE)/libucontext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/libucontext/.build_complete
endif

libucontext-package:
	@echo There's no need for a libucontext package.

.PHONY: libucontext

endif