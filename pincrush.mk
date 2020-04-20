ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += pincrush
DOWNLOAD         += https://github.com/DHowett/pincrush/archive/$(PINCRUSH_VERSION).tar.gz
PINCRUSH_VERSION := 0.9.2
DEB_PINCRUSH_V   ?= $(PINCRUSH_VERSION)

pincrush-setup: setup
	$(call EXTRACT_TAR,$(PINCRUSH_VERSION).tar.gz,pincrush-$(PINCRUSH_VERSION),pincrush)
	mkdir -p $(BUILD_STAGE)/pincrush/usr/bin

ifneq ($(wildcard $(BUILD_WORK)/pincrush/.build_complete),)
pincrush:
	@echo "Using previously built pincrush."
else
pincrush: pincrush-setup libpng16
	cd $(BUILD_WORK)/pincrush; \
	$(SED) -i '/#include <stdbool.h>/a #include <string.h>' pincrush.c; \
	$(CC) $(CFLAGS) $(LDFLAGS) -DVERSION=\"$(PINCRUSH_VERSION)\" -o $(BUILD_STAGE)/pincrush/usr/bin/pincrush pincrush.c -lpng16 -lz
	touch $(BUILD_WORK)/pincrush/.build_complete
endif

pincrush-package: pincrush-stage
	# pincrush.mk Package Structure
	rm -rf $(BUILD_DIST)/pincrush
	mkdir -p $(BUILD_DIST)/pincrush
	
	# pincrush.mk Prep pincrush
	cp -a $(BUILD_STAGE)/pincrush/usr $(BUILD_DIST)/pincrush
	
	# pincrush.mk Sign
	$(call SIGN,pincrush,general.xml)
	
	# pincrush.mk Make .debs
	$(call PACK,pincrush,DEB_PINCRUSH_V)
	
	# pincrush.mk Build cleanup
	rm -rf $(BUILD_DIST)/pincrush

.PHONY: pincrush pincrush-package
