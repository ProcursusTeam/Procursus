ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libcrack
LIBCRACK_VERSION := 2.9.7
DEB_LIBCRACK_V   ?= $(LIBCRACK_VERSION)

libcrack-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/cracklib/cracklib/releases/download/v$(LIBCRACK_VERSION)/cracklib-$(LIBCRACK_VERSION).tar.gz
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/cracklib/cracklib/releases/download/v$(LIBCRACK_VERSION)/cracklib-words-$(LIBCRACK_VERSION).gz
	$(call EXTRACT_TAR,cracklib-$(LIBCRACK_VERSION).tar.gz,cracklib-$(LIBCRACK_VERSION),libcrack)
	gzip -dc < $(BUILD_SOURCE)/cracklib-words-$(LIBCRACK_VERSION).gz > $(BUILD_WORK)/libcrack/dicts/libcrack-words

ifneq ($(wildcard $(BUILD_WORK)/libcrack/.build_complete),)
libcrack:
	@echo "Using previously built libcrack."
else
libcrack: libcrack-setup gettext
	cd $(BUILD_WORK)/libcrack && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-python \
		--with-default-dict=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/libcrack-words
	+$(MAKE) -C $(BUILD_WORK)/libcrack
	+$(MAKE) -C $(BUILD_WORK)/libcrack install \
		DESTDIR=$(BUILD_STAGE)/libcrack
	$(GINSTALL) -Dm 644 $(BUILD_WORK)/libcrack/dicts/libcrack-words -t "$(BUILD_STAGE)/libcrack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/libcrack"
	touch $(BUILD_WORK)/libcrack/.build_complete
endif

libcrack-package: libcrack-stage
	# libcrack.mk Package Structure
	rm -rf $(BUILD_DIST)/libcrack{2,-dev} $(BUILD_DIST)/cracklib-runtime
	mkdir -p $(BUILD_DIST)/libcrack{2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib,-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib} $(BUILD_DIST)/cracklib-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share}

	# libcrack.mk Prep cracklib-runtime
	cp -a $(BUILD_STAGE)/libcrack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/* $(BUILD_DIST)/cracklib-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libcrack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/libcrack $(BUILD_DIST)/cracklib-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libcrack.mk Prep libcrack2
	cp -a $(BUILD_STAGE)/libcrack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcrack.2.dylib $(BUILD_DIST)/libcrack2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libcrack.mk Prep libcrack-dev
	cp -a $(BUILD_STAGE)/libcrack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcrack-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libcrack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcrack.a,libcrack.dylib} $(BUILD_DIST)/libcrack-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libcrack.mk Sign
	$(call SIGN,cracklib-runtime,general.xml)
	$(call SIGN,libcrack2,general.xml)

	# libcrack.mk Make .debs
	$(call PACK,cracklib-runtime,DEB_LIBCRACK_V)
	$(call PACK,libcrack2,DEB_LIBCRACK_V)
	$(call PACK,libcrack-dev,DEB_LIBCRACK_V)

	# libcrack.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcrack{2,-dev} $(BUILD_DIST)/cracklib-runtime

.PHONY: libcrack libcrack-package
