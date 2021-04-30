ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += lame
LAME_VERSION := 3.100
DEB_LAME_V   ?= $(LAME_VERSION)

lame-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/lame/lame-$(LAME_VERSION).tar.gz
	$(call EXTRACT_TAR,lame-$(LAME_VERSION).tar.gz,lame-$(LAME_VERSION),lame)
	$(SED) -i '/lame_init_old/d' $(BUILD_WORK)/lame/include/libmp3lame.sym

ifneq ($(wildcard $(BUILD_WORK)/lame/.build_complete),)
lame:
	@echo "Using previously built lame."
else
lame: lame-setup ncurses libsndfile
	cd $(BUILD_WORK)/lame && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-dynamic-frontends \
		--with-fileio=sndfile
	$(SED) -i 's/-lncurses/-lncursesw/' $(BUILD_WORK)/lame/{,frontend/}Makefile
	+$(MAKE) -C $(BUILD_WORK)/lame
	+$(MAKE) -C $(BUILD_WORK)/lame install \
		DESTDIR=$(BUILD_STAGE)/lame
	+$(MAKE) -C $(BUILD_WORK)/lame install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/lame/.build_complete
endif

lame-package: lame-stage
	# lame.mk Package Structure
	rm -rf $(BUILD_DIST)/lame \
		$(BUILD_DIST)/libmp3lame{0,-dev}
	mkdir -p $(BUILD_DIST)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/libmp3lame{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lame.mk Prep lame
	cp -a $(BUILD_STAGE)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# lame.mk Prep libmp3lame0
	cp -a $(BUILD_STAGE)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmp3lame.0.dylib $(BUILD_DIST)/libmp3lame0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lame.mk Prep libmp3lame-dev
	cp -a $(BUILD_STAGE)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmp3lame.{dylib,a} $(BUILD_DIST)/libmp3lame-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/lame/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmp3lame-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# lame.mk Sign
	$(call SIGN,lame,general.xml)
	$(call SIGN,libmp3lame0,general.xml)

	# lame.mk Make .debs
	$(call PACK,lame,DEB_LAME_V)
	$(call PACK,libmp3lame0,DEB_LAME_V)
	$(call PACK,libmp3lame-dev,DEB_LAME_V)

	# lame.mk Build cleanup
	rm -rf $(BUILD_DIST)/lame \
		$(BUILD_DIST)/libmp3lame{0,-dev}

.PHONY: lame lame-package
