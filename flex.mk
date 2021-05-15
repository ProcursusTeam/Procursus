ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += flex
FLEX_VERSION := 2.6.4
DEB_FLEX_V   ?= $(FLEX_VERSION)-2

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
FLEX_LDFLAGS := -Wl,-flat_namespace -Wl,-undefined -Wl,suppress
endif

flex-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/westes/flex/releases/download/v$(FLEX_VERSION)/flex-$(FLEX_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,flex-$(FLEX_VERSION).tar.gz)
	$(call EXTRACT_TAR,flex-$(FLEX_VERSION).tar.gz,flex-$(FLEX_VERSION),flex)

ifneq ($(wildcard $(BUILD_WORK)/flex/.build_complete),)
flex:
	@echo "Using previously built flex."
else
flex: flex-setup gettext
	cd $(BUILD_WORK)/flex && ./autogen.sh
	cd $(BUILD_WORK)/flex && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes \
		ac_cv_path_M4="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/m4"
	+$(MAKE) -C $(BUILD_WORK)/flex \
		LIBS="-lm -lintl -Wl,-framework -Wl,CoreFoundation" \
		LDFLAGS="$(LDFLAGS) $(FLEX_LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/flex install \
		DESTDIR="$(BUILD_STAGE)/flex"
	+$(MAKE) -C $(BUILD_WORK)/flex install \
		DESTDIR="$(BUILD_BASE)"
	ln -s flex $(BUILD_STAGE)/flex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lex
	touch $(BUILD_WORK)/flex/.build_complete
endif

flex-package: flex-stage
	# flex.mk Package Structure
	rm -rf $(BUILD_DIST)/flex $(BUILD_DIST)/libfl{2,-dev}
	mkdir -p $(BUILD_DIST)/flex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libfl{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \

	# flex.mk Prep flex
	cp -a $(BUILD_STAGE)/flex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/flex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# flex.mk Prep libfl2
	cp -a $(BUILD_STAGE)/flex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfl.2.dylib $(BUILD_DIST)/libfl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# flex.mk Prep libfl-dev
	cp -a $(BUILD_STAGE)/flex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libfl.2.dylib) $(BUILD_DIST)/libfl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/flex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libfl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# flex.mk Sign
	$(call SIGN,flex,general.xml)
	$(call SIGN,libfl2,general.xml)

	# flex.mk Make .debs
	$(call PACK,flex,DEB_FLEX_V)
	$(call PACK,libfl2,DEB_FLEX_V)
	$(call PACK,libfl-dev,DEB_FLEX_V)

	# flex.mk Build cleanup
	rm -rf $(BUILD_DIST)/flex $(BUILD_DIST)/libfl{2,-dev}

.PHONY: flex flex-package
