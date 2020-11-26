ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += flex
FLEX_VERSION := 2.6.4
DEB_FLEX_V   ?= $(FLEX_VERSION)

flex-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/westes/flex/releases/download/v$(FLEX_VERSION)/flex-$(FLEX_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,flex-$(FLEX_VERSION).tar.gz)
	$(call EXTRACT_TAR,flex-$(FLEX_VERSION).tar.gz,flex-$(FLEX_VERSION),flex)

ifneq ($(wildcard $(BUILD_WORK)/flex/.build_complete),)
flex:
	@echo "Using previously built flex."
else
flex: flex-setup gettext
	cd $(BUILD_WORK)/flex && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/flex \
		LIBS="-lm -lintl -Wl,-framework -Wl,CoreFoundation"
	+$(MAKE) -C $(BUILD_WORK)/flex install \
		DESTDIR="$(BUILD_STAGE)/flex"
	+$(MAKE) -C $(BUILD_WORK)/flex install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/flex/.build_complete
endif

flex-package: flex-stage
	# flex.mk Package Structure
	rm -rf $(BUILD_DIST)/flex $(BUILD_DIST)/libfl{2,-dev}
	mkdir -p $(BUILD_DIST)/flex/usr \
		$(BUILD_DIST)/libfl{2,-dev}/usr/lib \
	
	# flex.mk Prep flex
	cp -a $(BUILD_STAGE)/flex/usr/{bin,share} $(BUILD_DIST)/flex/usr

	# flex.mk Prep libfl2
	cp -a $(BUILD_STAGE)/flex/usr/lib/libfl.2.dylib $(BUILD_DIST)/libfl2/usr/lib

	# flex.mk Prep libfl-dev
	cp -a $(BUILD_STAGE)/flex/usr/lib/!(libfl.2.dylib) $(BUILD_DIST)/libfl-dev/usr/lib
	cp -a $(BUILD_STAGE)/flex/usr/include $(BUILD_DIST)/libfl-dev/usr
	
	# flex.mk Sign
	$(call SIGN,flex,general.xml)
	$(call SIGN,libfl2,general.xml)
	
	# flex.mk Make .debs
	$(call PACK,flex,DEB_FLEX_V)
	$(call PACK,libfl2,DEB_FLEX_V)
	$(call PACK,libfl-dev,DEB_FLEX_V)
	
	# flex.mk Build cleanup
	rm -rf $(BUILD_DIST)/flex $(BUILD_DIST)/libfl{2,-dev}
	
.PHONY: flex flex-package
