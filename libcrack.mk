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
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-python \
		--with-default-dict=/usr/share/libcrack-words
	+$(MAKE) -C $(BUILD_WORK)/libcrack
	+$(MAKE) -C $(BUILD_WORK)/libcrack install \
		DESTDIR=$(BUILD_STAGE)/libcrack
	$(GINSTALL) -Dm 644 $(BUILD_WORK)/libcrack/dicts/libcrack-words -t "$(BUILD_STAGE)/libcrack/usr/share/libcrack"
	touch $(BUILD_WORK)/libcrack/.build_complete
endif

libcrack-package: libcrack-stage
	# libcrack.mk Package Structure
	rm -rf $(BUILD_DIST)/libcrack{2,-dev} $(BUILD_DIST)/cracklib-runtime
	mkdir -p $(BUILD_DIST)/libcrack{2/usr/lib,-dev/usr/lib} $(BUILD_DIST)/cracklib-runtime/usr/{bin,share}
	
	# libcrack.mk Prep cracklib-runtime
	cp -a $(BUILD_STAGE)/libcrack/usr/sbin/* $(BUILD_DIST)/cracklib-runtime/usr/bin
	cp -a $(BUILD_STAGE)/libcrack/usr/share/libcrack $(BUILD_DIST)/cracklib-runtime/usr/share

	# libcrack.mk Prep libcrack2
	cp -a $(BUILD_STAGE)/libcrack/usr/lib/libcrack.2.dylib $(BUILD_DIST)/libcrack2/usr/lib

	# libcrack.mk Prep libcrack-dev
	cp -a $(BUILD_STAGE)/libcrack/usr/include $(BUILD_DIST)/libcrack-dev/usr
	cp -a $(BUILD_STAGE)/libcrack/usr/lib/{libcrack.a,libcrack.dylib} $(BUILD_DIST)/libcrack-dev/usr/lib
	
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
