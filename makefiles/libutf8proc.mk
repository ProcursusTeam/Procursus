ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libutf8proc
LIBUTF8PROC_VERSION := 2.5.0
DEB_LIBUTF8PROC_V   ?= $(LIBUTF8PROC_VERSION)-2

libutf8proc-setup: setup
	$(call GITHUB_ARCHIVE,JuliaStrings,utf8proc,$(LIBUTF8PROC_VERSION),v$(LIBUTF8PROC_VERSION),libutf8proc)
	$(call EXTRACT_TAR,libutf8proc-$(LIBUTF8PROC_VERSION).tar.gz,utf8proc-$(LIBUTF8PROC_VERSION),libutf8proc)

ifneq ($(wildcard $(BUILD_WORK)/libutf8proc/.build_complete),)
libutf8proc:
	@echo "Using previously built libutf8proc."
else
libutf8proc: libutf8proc-setup
	+$(MAKE) -C $(BUILD_WORK)/libutf8proc install \
		OS=Darwin \
		prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/libutf8proc"
	+$(MAKE) -C $(BUILD_WORK)/libutf8proc install \
		OS=Darwin \
		prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libutf8proc/.build_complete
endif

libutf8proc-package: libutf8proc-stage
	# libutf8proc.mk Package Structure
	rm -rf $(BUILD_DIST)/libutf8proc{2,-dev}
	mkdir -p $(BUILD_DIST)/libutf8proc{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libutf8proc.mk Prep libutf8proc-dev
	cp -a $(BUILD_STAGE)/libutf8proc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libutf8proc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libutf8proc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libutf8proc.{a,dylib}} $(BUILD_DIST)/libutf8proc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libutf8proc.mk Prep libutf8proc2
	cp -a $(BUILD_STAGE)/libutf8proc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libutf8proc.2.dylib $(BUILD_DIST)/libutf8proc2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libutf8proc.mk Sign
	$(call SIGN,libutf8proc-dev,general.xml)
	$(call SIGN,libutf8proc2,general.xml)

	# libutf8proc.mk Make .debs
	$(call PACK,libutf8proc-dev,DEB_LIBUTF8PROC_V)
	$(call PACK,libutf8proc2,DEB_LIBUTF8PROC_V)

	# libutf8proc.mk Build cleanup
	rm -rf $(BUILD_DIST)/libutf8proc{2,-dev}

.PHONY: libutf8proc libutf8proc-package
