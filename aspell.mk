ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += aspell
ASPELL_VERSION  := 0.60.8
DEB_ASPELL_V    ?= $(ASPELL_VERSION)

aspell-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/aspell/aspell-$(ASPELL_VERSION).tar.gz
	$(call EXTRACT_TAR,aspell-$(ASPELL_VERSION).tar.gz,aspell-$(ASPELL_VERSION),aspell)

ifneq ($(wildcard $(BUILD_WORK)/aspell/.build_complete),)
aspell:
	@echo "Using previously built aspell."
else
aspell: aspell-setup ncurses
	cd $(BUILD_WORK)/aspell && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-rpath
	+$(MAKE) -C $(BUILD_WORK)/aspell
	+$(MAKE) -C $(BUILD_WORK)/aspell install \
		DESTDIR=$(BUILD_STAGE)/aspell
	+$(MAKE) -C $(BUILD_WORK)/aspell install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/aspell/.build_complete
endif

aspell-package: aspell-stage
# aspell.mk Package Structure
	rm -rf $(BUILD_DIST)/{aspell,libaspell-dev,libaspell15,libpspell-dev}
	mkdir -p $(BUILD_DIST)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libaspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
		$(BUILD_DIST)/libaspell15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/aspell-0.60} \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include/pspell,bin}

# aspell.mk Prep aspell
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(pspell-config) \
		$(BUILD_DIST)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

# aspell.mk Prep aspell-dev
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/aspell.h \
		$(BUILD_DIST)/libaspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaspell.la \
		$(BUILD_DIST)/libaspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

# aspell.mk Prep libaspell15
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/aspell-0.60 \
		$(BUILD_DIST)/libaspell15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/aspell-0.60
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libaspell.dylib,libaspell.15.dylib} \
		$(BUILD_DIST)/libaspell15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

# aspell.mk Prep libpspell-dev
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pspell/pspell.h \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pspell-config \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libpspell.la,libpspell.dylib,libpspell.15.dylib} \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

# aspell.mk Sign
	$(call SIGN,aspell,general.xml)
	$(call SIGN,libaspell-dev,general.xml)
	$(call SIGN,libaspell15,general.xml)
	$(call SIGN,libpspell-dev,general.xml)

# aspell.mk Make .debs
	$(call PACK,aspell,DEB_ASPELL_V)
	$(call PACK,libaspell-dev,DEB_ASPELL_V)
	$(call PACK,libaspell15,DEB_ASPELL_V)
	$(call PACK,libpspell-dev,DEB_ASPELL_V)

	# aspell.mk Build cleanup

.PHONY: aspell aspell-package
