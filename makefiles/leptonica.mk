ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += leptonica
LEPTONICA_VERSION := 1.80.0
DEB_LEPTONICA_V   ?= $(LEPTONICA_VERSION)

leptonica-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://www.leptonica.org/source/leptonica-$(LEPTONICA_VERSION).tar.gz
	$(call EXTRACT_TAR,leptonica-$(LEPTONICA_VERSION).tar.gz,leptonica-$(LEPTONICA_VERSION),leptonica)

ifneq ($(wildcard $(BUILD_WORK)/leptonica/.build_complete),)
leptonica:
	@echo "Using previously built leptonica."
else
leptonica: leptonica-setup libgif libjpeg-turbo libpng16 libtiff openjpeg libwebp
	cd $(BUILD_WORK)/leptonica && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libwebp \
		--with-libopenjpeg
	+$(MAKE) -C $(BUILD_WORK)/leptonica
	+$(MAKE) -C $(BUILD_WORK)/leptonica install \
		DESTDIR="$(BUILD_STAGE)/leptonica"
	rm -rf $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libleptonica*
	+$(MAKE) -C $(BUILD_WORK)/leptonica install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/leptonica/.build_complete
endif

leptonica-package: leptonica-stage
	# leptonica.mk Package Structure
	rm -rf $(BUILD_DIST)/liblept5 $(BUILD_DIST)/libleptonica-dev $(BUILD_DIST)/leptonica-progs
	mkdir -p \
		$(BUILD_DIST)/libleptonica-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/leptonica-progs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/liblept5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# leptonica.mk Prep libleptonica-dev
	cp -a $(BUILD_STAGE)/leptonica/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libleptonica-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/leptonica/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(liblept.5.dylib) $(BUILD_DIST)/libleptonica-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# leptonica.mk Prep leptonica-progs
	cp -a $(BUILD_STAGE)/leptonica/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/leptonica-progs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# leptonica.mk Prep liblept5
	cp -a $(BUILD_STAGE)/leptonica/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblept.5.dylib $(BUILD_DIST)/liblept5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# leptonica.mk Sign
	$(call SIGN,liblept5,general.xml)
	$(call SIGN,leptonica-progs,general.xml)

	# leptonica.mk Make .debs
	$(call PACK,libleptonica-dev,DEB_LEPTONICA_V)
	$(call PACK,leptonica-progs,DEB_LEPTONICA_V)
	$(call PACK,liblept5,DEB_LEPTONICA_V)

	# leptonica.mk Build cleanup
	rm -rf $(BUILD_DIST)/liblept5 $(BUILD_DIST)/libleptonica-dev $(BUILD_DIST)/leptonica-progs

.PHONY: leptonica leptonica-package
