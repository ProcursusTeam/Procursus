ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += icu4c
ICU_VERSION  := 69.1
DEB_ICU_V    ?= $(ICU_VERSION)

icu4c-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://github.com/unicode-org/icu/releases/download/release-$(shell echo $(ICU_VERSION) | $(SED) 's/\./-/')/icu4c-$(shell echo $(ICU_VERSION) | $(SED) 's/\./_/g')-src.tgz
	$(call EXTRACT_TAR,icu4c-$(shell echo $(ICU_VERSION) | $(SED) 's/\./_/g')-src.tgz,icu,icu4c)
	mkdir -p $(BUILD_WORK)/icu4c/host

ifneq ($(wildcard $(BUILD_WORK)/icu4c/.build_complete),)
icu4c:
	@echo "Using previously built icu4c."
else
icu4c: .SHELLFLAGS=-O extglob -c
icu4c: icu4c-setup
	cd $(BUILD_WORK)/icu4c/host && ../source/configure \
			$(BUILD_CONFIGURE_FLAGS); \
		$(MAKE) -C $(BUILD_WORK)/icu4c/host
	cd $(BUILD_WORK)/icu4c/source && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-cross-build=$(BUILD_WORK)/icu4c/host \
		--disable-samples \
		--disable-tests \
		LDFLAGS="$(LDFLAGS) -headerpad_max_install_names"
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_STAGE)/icu4c
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/icu4c/.build_complete

	for lib in $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib; do \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/$$(echo $$lib | rev | cut -d. -f4 | cut -d/ -f1 | rev).$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$lib; \
		ln -sf $$(echo $$lib | rev | cut -d. -f4 | cut -d/ -f1 | rev).$(ICU_VERSION).dylib $$(echo $$lib | rev | cut -d. -f4 | rev).$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib; \
		ln -sf $$(echo $$lib | rev | cut -d. -f4 | cut -d/ -f1 | rev).$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$(echo $$lib | rev | cut -d. -f4 | rev).dylib; \
	done

	for stuff in $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(icu-config); do \
		$(I_N_T) -change libicudata.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicudata.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$stuff; \
		$(I_N_T) -change libicui18n.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicui18n.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$stuff; \
		$(I_N_T) -change libicuio.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicuio.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$stuff; \
		$(I_N_T) -change libicutest.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicutest.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$stuff; \
		$(I_N_T) -change libicutu.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicutu.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$stuff; \
		$(I_N_T) -change libicuuc.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicuuc.$(shell echo $(ICU_VERSION) | cut -f1 -d.).dylib $$stuff; \
	done
endif

icu4c-package: icu4c-stage
	# icu4c.mk Package Structure
	rm -rf $(BUILD_DIST)/libicu{$(shell echo $(ICU_VERSION) | cut -f1 -d.),-dev} \
		$(BUILD_DIST)/icu-devtools
	mkdir -p $(BUILD_DIST)/libicu{$(shell echo $(ICU_VERSION) | cut -f1 -d.),-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# icu4c.mk Prep libicu$(shell echo $(ICU_VERSION) | cut -f1 -d.)
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(shell echo $(ICU_VERSION) | cut -f1 -d.)*.dylib $(BUILD_DIST)/libicu$(shell echo $(ICU_VERSION) | cut -f1 -d.)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# icu4c.mk Prep libicu-dev
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu{data,i18n,io,test,tu,uc}.dylib $(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,icu} $(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/icu $(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# icu4c.mk Prep icu-devtools
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,bin,share} $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	rm -f $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/icu-config
	rm -f $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/icu-config.1
	rm -rf $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/icu

	# icu4c.mk Sign
	$(call SIGN,libicu$(shell echo $(ICU_VERSION) | cut -f1 -d.),general.xml)
	$(call SIGN,icu-devtools,general.xml)

	# icu4c.mk Make .debs
	$(call PACK,libicu$(shell echo $(ICU_VERSION) | cut -f1 -d.),DEB_ICU_V)
	$(call PACK,libicu-dev,DEB_ICU_V)
	$(call PACK,icu-devtools,DEB_ICU_V)

	# icu4c.mk Build cleanup
	rm -rf $(BUILD_DIST)/libicu{$(shell echo $(ICU_VERSION) | cut -f1 -d.),-dev} \
		$(BUILD_DIST)/icu-devtools

.PHONY: icu4c icu4c-package
