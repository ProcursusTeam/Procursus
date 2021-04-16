ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += jbig2dec
JBIG2DEC_VERSION := 0.19
DEB_JBIG2DEC_V   ?= $(JBIG2DEC_VERSION)

jbig2dec-setup: setup
	$(call GITHUB_ARCHIVE,ArtifexSoftware,jbig2dec,$(JBIG2DEC_VERSION),$(JBIG2DEC_VERSION))
	$(call EXTRACT_TAR,jbig2dec-$(JBIG2DEC_VERSION).tar.gz,jbig2dec-$(JBIG2DEC_VERSION),jbig2dec)

ifneq ($(wildcard $(BUILD_WORK)/jbig2dec/.build_complete),)
jbig2dec:
	@echo "Using previously built jbig2dec."
else
jbig2dec: jbig2dec-setup libpng16
	cd $(BUILD_WORK)/jbig2dec && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/jbig2dec
	+$(MAKE) -C $(BUILD_WORK)/jbig2dec install \
		DESTDIR="$(BUILD_STAGE)/jbig2dec"
	+$(MAKE) -C $(BUILD_WORK)/jbig2dec install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/jbig2dec/.build_complete
endif

jbig2dec-package: jbig2dec-stage
	# jbig2dec.mk Package Structure
	rm -rf $(BUILD_DIST)/jbig2dec \
		$(BUILD_DIST)/libjbig2dec0{,-dev}
	mkdir -p $(BUILD_DIST)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/libjbig2dec0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libjbig2dec0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# jbig2dec.mk Prep jbig2dec
	cp -a $(BUILD_STAGE)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jbig2dec $(BUILD_DIST)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/jbig2dec.1 $(BUILD_DIST)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# jbig2dec.mk Prep libjbig2dec0
	cp -a $(BUILD_STAGE)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjbig2dec.0.dylib $(BUILD_DIST)/libjbig2dec0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# jbig2dec.mk Prep libjbig2dec0-dev
	cp -a $(BUILD_STAGE)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libjbig2dec.0.dylib) $(BUILD_DIST)/libjbig2dec0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/jbig2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libjbig2dec0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# jbig2dec.mk Sign
	$(call SIGN,jbig2dec,general.xml)
	$(call SIGN,libjbig2dec0,general.xml)

	# jbig2dec.mk Make .debs
	$(call PACK,jbig2dec,DEB_JBIG2DEC_V)
	$(call PACK,libjbig2dec0,DEB_JBIG2DEC_V)
	$(call PACK,libjbig2dec0-dev,DEB_JBIG2DEC_V)

	# jbig2dec.mk Build cleanup
	rm -rf $(BUILD_DIST)/jbig2dec \
		$(BUILD_DIST)/libjbig2dec0{,-dev}

.PHONY: jbig2dec jbig2dec-package
