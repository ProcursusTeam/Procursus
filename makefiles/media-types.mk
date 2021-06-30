ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += media-types
MEDIA_TYPES_VERSION := 4.0.0
DEB_MEDIA_TYPES_V   ?= $(MEDIA_TYPES_VERSION)

media-types-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://salsa.debian.org/debian/media-types/-/archive/$(MEDIA_TYPES_VERSION)/media-types-$(MEDIA_TYPES_VERSION).tar.gz
	$(call EXTRACT_TAR,media-types-$(MEDIA_TYPES_VERSION).tar.gz,media-types-$(MEDIA_TYPES_VERSION),media-types)

media-types: media-types-setup
	@echo "Nothing to build for media-types."

media-types-package: media-types-stage
	# media-types.mk Package Structure
	rm -rf $(BUILD_DIST)/media-types
	mkdir -p $(BUILD_DIST)/media-types/$(MEMO_PREFIX)/etc
	
	# media-types.mk Prep media-types
	cp -a $(BUILD_WORK)/media-types/mime.types $(BUILD_DIST)/media-types/$(MEMO_PREFIX)/etc/
	
	# media-types.mk Make .debs
	$(call PACK,media-types,DEB_MEDIA_TYPES_V)
	
	# media-types.mk Build cleanup
	rm -rf $(BUILD_DIST)/media-types

.PHONY: media-types media-types-package
