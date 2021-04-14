ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += mpg123
MPG123_VERSION := 1.26.3
DEB_MPG123_V   ?= $(MPG123_VERSION)

mpg123-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.mpg123.de/download/mpg123-$(MPG123_VERSION).tar.bz2
	$(call EXTRACT_TAR,mpg123-$(MPG123_VERSION).tar.bz2,mpg123-$(MPG123_VERSION),mpg123)

ifneq ($(wildcard $(BUILD_WORK)/mpg123/.build_complete),)
mpg123:
	@echo "Using previously built mpg123."
else
mpg123: mpg123-setup
	cd $(BUILD_WORK)/mpg123 && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-audio=coreaudio \
		--with-cpu=aarch64
	+$(MAKE) -C $(BUILD_WORK)/mpg123 install \
		DESTDIR=$(BUILD_STAGE)/mpg123
	touch $(BUILD_WORK)/mpg123/.build_complete
endif

mpg123-package: mpg123-stage
	# mpg123.mk Package Structure
	rm -rf $(BUILD_DIST)/mpg123 $(BUILD_DIST)/lib{mpg,out,syn}123-{0,dev}
	mkdir -p $(BUILD_DIST)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libmpg123-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libout123-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libsyn123-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libmpg123-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpg123.mk Prep mpg123
	cp -a $(BUILD_STAGE)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mpg123 $(BUILD_DIST)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpg123.mk Prep libmpg123-0
	cp -a $(BUILD_STAGE)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmpg123.0.dylib $(BUILD_DIST)/libmpg123-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpg123.mk Prep libout123-0
	cp -a $(BUILD_STAGE)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libout123.0.dylib $(BUILD_DIST)/libout123-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpg123.mk Prep libsyn123-0
	cp -a $(BUILD_STAGE)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsyn123.0.dylib $(BUILD_DIST)/libsyn123-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpg123.mk Prep libmpg123-dev
	cp -a $(BUILD_STAGE)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.0.*|mpg123) $(BUILD_DIST)/libmpg123-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mpg123/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmpg123-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# mpg123.mk Sign
	$(call SIGN,mpg123,general.xml)
	$(call SIGN,libmpg123-0,general.xml)
	$(call SIGN,libout123-0,general.xml)
	$(call SIGN,libsyn123-0,general.xml)

	# mpg123.mk Make .debs
	$(call PACK,mpg123,DEB_MPG123_V)
	$(call PACK,libmpg123-0,DEB_MPG123_V)
	$(call PACK,libout123-0,DEB_MPG123_V)
	$(call PACK,libsyn123-0,DEB_MPG123_V)
	$(call PACK,libmpg123-dev,DEB_MPG123_V)

	# mpg123.mk Build cleanup
	rm -rf $(BUILD_DIST)/mpg123 $(BUILD_DIST)/lib{mpg,out,syn}123-{0,dev}

.PHONY: mpg123 mpg123-package
