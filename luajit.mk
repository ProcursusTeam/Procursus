ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += luajit
LUAJIT_VERSION := 2.1.0-beta3
DEB_LUAJIT_V   ?= $(shell echo $(LUAJIT_VERSION) | cut -d- -f1)~beta3

luajit-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://luajit.org/download/LuaJIT-$(LUAJIT_VERSION).tar.gz
	$(call EXTRACT_TAR,luajit-$(LUAJIT_VERSION).tar.gz,luajit-$(LUAJIT_VERSION),luajit)
	$(SED) -i 's/#BUILDMODE= dynamic/BUILDMODE= dynamic/' $(BUILD_WORK)/luajit/src/Makefile

ifneq ($(wildcard $(BUILD_WORK)/luajit/.build_complete),)
luajit:
	@echo "Using previously built luajit."
else
luajit: luajit-setup
	+unset CC CFLAGS CXXFLAGS CPPFLAGS LDFLAGS && $(MAKE) -C $(BUILD_WORK)/luajit \
		DYNAMIC_CC="$(CC) -fPIC" \
		STATIC_CC="$(CC)" \
		TARGET_CFLAGS="$(CFLAGS)" \
		TARGET_LDFLAGS="$(LDFLAGS)" \
		TARGET_SHLDFLAGS="$(LDFLAGS)" \
		TARGET_SYS=Darwin \
		PREFIX=/usr
	+$(MAKE) -C $(BUILD_WORK)/luajit install \
		DESTDIR="$(BUILD_STAGE)/luajit" \
		PREFIX=/usr
	mv $(BUILD_STAGE)/luajit/usr/bin/luajit-$(LUAJIT_VERSION) $(BUILD_STAGE)/luajit/usr/bin/luajit
	touch $(BUILD_WORK)/luajit/.build_complete
endif

luajit-package: luajit-stage
	# luajit.mk Package Structure
	rm -rf $(BUILD_DIST)/luajit $(BUILD_DIST)/libluajit-5.1-{2,dev,common}
	mkdir -p $(BUILD_DIST)/luajit/usr/share \
		$(BUILD_DIST)/libluajit-5.1-{2,dev}/usr/lib \
		$(BUILD_DIST)/libluajit-5.1-common/usr/share
	
	# luajit.mk Prep luajit
	cp -a $(BUILD_STAGE)/luajit/usr/bin $(BUILD_DIST)/luajit/usr
	cp -a $(BUILD_STAGE)/luajit/usr/share/man $(BUILD_DIST)/luajit/usr/share

	# luajit.mk Prep libluajit-5.1-2
	cp -a $(BUILD_STAGE)/luajit/usr/lib/libluajit-5.1.2*.dylib $(BUILD_DIST)/libluajit-5.1-2/usr/lib

	# luajit.mk Prep libluajit-5.1-dev
	cp -a $(BUILD_STAGE)/luajit/usr/lib/!(libluajit-5.1.2*.dylib) $(BUILD_DIST)/libluajit-5.1-dev/usr/lib
	cp -a $(BUILD_STAGE)/luajit/usr/include $(BUILD_DIST)/libluajit-5.1-dev/usr

	# luajit.mk Prep libluajit-5.1-common
	cp -a $(BUILD_STAGE)/luajit/usr/share/lua* $(BUILD_DIST)/libluajit-5.1-common/usr/share
	
	# luajit.mk Sign
	$(call SIGN,luajit,general.xml)
	$(call SIGN,libluajit-5.1-2,general.xml)
	
	# luajit.mk Make .debs
	$(call PACK,luajit,DEB_LUAJIT_V)
	$(call PACK,libluajit-5.1-2,DEB_LUAJIT_V)
	$(call PACK,libluajit-5.1-dev,DEB_LUAJIT_V)
	$(call PACK,libluajit-5.1-common,DEB_LUAJIT_V)
	
	# luajit.mk Build cleanup
	rm -rf $(BUILD_DIST)/luajit $(BUILD_DIST)/libluajit-5.1-{2,dev,common}

.PHONY: luajit luajit-package
