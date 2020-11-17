ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += cracklib
CRACKLIB_VERSION := 2.9.7
DEB_CRACKLIB_V   ?= $(CRACKLIB_VERSION)

cracklib-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/cracklib/cracklib/releases/download/v$(CRACKLIB_VERSION)/cracklib-$(CRACKLIB_VERSION).tar.gz
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/cracklib/cracklib/releases/download/v$(CRACKLIB_VERSION)/cracklib-words-$(CRACKLIB_VERSION).gz
	$(call EXTRACT_TAR,cracklib-$(CRACKLIB_VERSION).tar.gz,cracklib-$(CRACKLIB_VERSION),cracklib)
	gzip -dc < $(BUILD_SOURCE)/cracklib-words-$(CRACKLIB_VERSION).gz > $(BUILD_WORK)/cracklib/dicts/cracklib-words

ifneq ($(wildcard $(BUILD_WORK)/cracklib/.build_complete),)
cracklib:
	@echo "Using previously built cracklib."
else
cracklib: cracklib-setup
	cd $(BUILD_WORK)/cracklib && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-python
		#--with-default-dict/usr/share/cracklib-words
	+$(MAKE) -C $(BUILD_WORK)/cracklib
	+$(MAKE) -C $(BUILD_WORK)/cracklib install \
		DESTDIR=$(BUILD_STAGE)/cracklib
	$(GINSTALL) -Dm 644 $(BUILD_WORK)/cracklib/dicts/cracklib-words -t "$(BUILD_STAGE)/cracklib/usr/share/cracklib"
	touch $(BUILD_WORK)/cracklib/.build_complete
endif

cracklib-package: cracklib-stage
	# cracklib.mk Package Structure
	rm -rf $(BUILD_DIST)/cracklib{-bin,2,-dev}
	mkdir -p $(BUILD_DIST)/cracklib{-bin/usr/{bin,share},2/usr/lib,-dev/usr/lib}
	
	# cracklib.mk Prep cracklib-bin
	cp -a $(BUILD_STAGE)/cracklib/usr/sbin/* $(BUILD_DIST)/cracklib-bin/usr/bin
	cp -a $(BUILD_STAGE)/cracklib/usr/share/cracklib $(BUILD_DIST)/cracklib-bin/usr/share

	# cracklib.mk Prep cracklib2
	cp -a $(BUILD_STAGE)/cracklib/usr/lib/libcrack.2.dylib $(BUILD_DIST)/cracklib2/usr/lib

	# cracklib.mk Prep cracklib-dev
	cp -a $(BUILD_STAGE)/cracklib/usr/include $(BUILD_DIST)/cracklib-dev/usr
	cp -a $(BUILD_STAGE)/cracklib/usr/lib/{libcrack.a,libcrack.dylib} $(BUILD_DIST)/cracklib-dev/usr/lib
	
	# cracklib.mk Sign
	$(call SIGN,cracklib-bin,general.xml)
	$(call SIGN,cracklib2,general.xml)
	
	# cracklib.mk Make .debs
	$(call PACK,cracklib-bin,DEB_CRACKLIB_V)
	$(call PACK,cracklib2,DEB_CRACKLIB_V)
	$(call PACK,cracklib-dev,DEB_CRACKLIB_V)
	
	# cracklib.mk Build cleanup
	rm -rf $(BUILD_DIST)/cracklib{-bin,2,-dev}

.PHONY: cracklib cracklib-package
