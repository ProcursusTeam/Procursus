ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += luajit
LUAJIT_VERSION := 2.1.0-beta3
DEB_LUAJIT_V   ?= $(shell echo $(LUAJIT_VERSION) | cut -d- -f1)~beta3+git$(shell echo $(LUAJIT_COMMIT) | cut -c -7)

LUAJIT_COMMIT    := 377a8488b62a9f1b589bb68875dd1288aa70e76e

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
LUAJIT_MAKE_ARGS := TARGET_SYS=Darwin
else
LUAJIT_MAKE_ARGS := TARGET_SYS=iOS
endif

luajit-setup: setup
	$(call GITHUB_ARCHIVE,LuaJIT,LuaJIT,$(LUAJIT_COMMIT),$(LUAJIT_COMMIT))
	$(call EXTRACT_TAR,LuaJIT-$(LUAJIT_COMMIT).tar.gz,LuaJIT-$(LUAJIT_COMMIT),luajit)
	$(SED) -i 's/#BUILDMODE= dynamic/BUILDMODE= dynamic/' $(BUILD_WORK)/luajit/src/Makefile
	$(SED) -i 's/#define LJ_OS_NOJIT		1/#undef LJ_OS_NOJIT/' $(BUILD_WORK)/luajit/src/lj_arch.h

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
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(LUAJIT_MAKE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/luajit install \
		DESTDIR="$(BUILD_STAGE)/luajit" \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/luajit install \
		DESTDIR="$(BUILD_BASE)" \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mv $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/luajit-$(LUAJIT_VERSION) $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/luajit
	touch $(BUILD_WORK)/luajit/.build_complete
endif

luajit-package: luajit-stage
	# luajit.mk Package Structure
	rm -rf $(BUILD_DIST)/luajit $(BUILD_DIST)/libluajit-5.1-{2,dev,common}
	mkdir -p $(BUILD_DIST)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/libluajit-5.1-{2,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libluajit-5.1-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# luajit.mk Prep luajit
	cp -a $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# luajit.mk Prep libluajit-5.1-2
	cp -a $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1.2*.dylib $(BUILD_DIST)/libluajit-5.1-2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# luajit.mk Prep libluajit-5.1-dev
	cp -a $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libluajit-5.1.2*.dylib) $(BUILD_DIST)/libluajit-5.1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libluajit-5.1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# luajit.mk Prep libluajit-5.1-common
	cp -a $(BUILD_STAGE)/luajit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lua* $(BUILD_DIST)/libluajit-5.1-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

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
