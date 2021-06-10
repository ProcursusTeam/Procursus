ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += harfbuzz
HARFBUZZ_VERSION := 2.8.1
DEB_HARFBUZZ_V   ?= $(HARFBUZZ_VERSION)

harfbuzz-setup: setup
	$(call GITHUB_ARCHIVE,harfbuzz,harfbuzz,$(HARFBUZZ_VERSION),$(HARFBUZZ_VERSION))
	$(call EXTRACT_TAR,harfbuzz-$(HARFBUZZ_VERSION).tar.gz,harfbuzz-$(HARFBUZZ_VERSION),harfbuzz)

ifneq ($(wildcard $(BUILD_WORK)/harfbuzz/.build_complete),)
harfbuzz:
	@echo "Using previously built harfbuzz."
else
harfbuzz: harfbuzz-setup cairo freetype glib2.0 graphite2 icu4c fontconfig
	cd $(BUILD_WORK)/harfbuzz && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-cairo \
		--with-freetype \
		--with-fontconfig \
		--with-glib \
		--with-gobject \
		--with-icu \
		--with-graphite2 \
		--with-coretext \
		--enable-introspection=no # Remove this when introspection is proper.
	+$(MAKE) -C $(BUILD_WORK)/harfbuzz
	+$(MAKE) -C $(BUILD_WORK)/harfbuzz install \
		DESTDIR="$(BUILD_STAGE)/harfbuzz"
	+$(MAKE) -C $(BUILD_WORK)/harfbuzz install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/harfbuzz/.build_complete
endif

harfbuzz-package: harfbuzz-stage
	# harfbuzz.mk Package Structure
	rm -rf $(BUILD_DIST)/libharfbuzz-{bin,dev,icu0,gobject0,subset0} \
		$(BUILD_DIST)/libharfbuzz0b
	mkdir -p $(BUILD_DIST)/libharfbuzz-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libharfbuzz-{dev,icu0,gobject0,subset0}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libharfbuzz0b/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# harfbuzz.mk Prep libharfbuzz0b
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libharfbuzz.0.dylib $(BUILD_DIST)/libharfbuzz0b/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# harfbuzz.mk Prep libharfbuzz-icu0
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libharfbuzz-icu.0.dylib $(BUILD_DIST)/libharfbuzz-icu0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# harfbuzz.mk Prep libharfbuzz-gobject0
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libharfbuzz-gobject.0.dylib $(BUILD_DIST)/libharfbuzz-gobject0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# harfbuzz.mk Prep libharfbuzz-subset0
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libharfbuzz-subset.0.dylib $(BUILD_DIST)/libharfbuzz-subset0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# harfbuzz.mk Prep libharfbuzz-dev
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libharfbuzz-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.0.*) $(BUILD_DIST)/libharfbuzz-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# harfbuzz.mk Prep libharfbuzz-bin
	cp -a $(BUILD_STAGE)/harfbuzz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libharfbuzz-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# harfbuzz.mk Sign
	$(call SIGN,libharfbuzz0b,general.xml)
	$(call SIGN,libharfbuzz-icu0,general.xml)
	$(call SIGN,libharfbuzz-gobject0,general.xml)
	$(call SIGN,libharfbuzz-subset0,general.xml)
	$(call SIGN,libharfbuzz-bin,general.xml)

	# harfbuzz.mk Make .debs
	$(call PACK,libharfbuzz0b,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-icu0,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-gobject0,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-subset0,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-bin,DEB_HARFBUZZ_V)
	$(call PACK,libharfbuzz-dev,DEB_HARFBUZZ_V)

	# harfbuzz.mk Build cleanup
	rm -rf $(BUILD_DIST)/libharfbuzz-{bin,dev,icu0,gobject0,subset0} \
		$(BUILD_DIST)/libharfbuzz0b

.PHONY: harfbuzz harfbuzz-package
