ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += portaudio
PORTAUDIO_VERSION    := 19.7.0
PORTAUDIO_DOWNLOAD_V := 190700_20210406
DEB_PORTAUDIO_V      ?= $(PORTAUDIO_VERSION)

portaudio-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/portaudio-$(PORTAUDIO_VERSION).tgz,http://files.portaudio.com/archives/pa_stable_v$(PORTAUDIO_DOWNLOAD_V).tgz)
	$(call EXTRACT_TAR,portaudio-$(PORTAUDIO_VERSION).tgz,portaudio-$(PORTAUDIO_VERSION),portaudio)
	$(call DO_PATCH,portaudio,portaudio,-p1)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,portaudio-ios,portaudio,-p1)
endif
	sed -i 's|-framework AudioUnit ||g' $(BUILD_WORK)/portaudio/configure.in

ifneq ($(wildcard $(BUILD_WORK)/portaudio/.build_complete),)
portaudio:
	@echo "Using previously built portaudio."
else
portaudio: portaudio-setup
	cd $(BUILD_WORK)/portaudio && autoreconf -fi
	cd $(BUILD_WORK)/portaudio/bindings/cpp && autoreconf -fi
	sed -i 's/-keep_private_externs -nostdlib/-keep_private_externs $(PLATFORM_VERSION_MIN) -nostdlib/g' $(BUILD_WORK)/portaudio/{,bindings/cpp}/configure
	cd $(BUILD_WORK)/portaudio && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-cxx \
		CC="$(CC) $(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/portaudio lib/libportaudio.la
	+$(MAKE) -C $(BUILD_WORK)/portaudio
	+$(MAKE) -C $(BUILD_WORK)/portaudio install \
		DESTDIR=$(BUILD_STAGE)/portaudio
	$(call AFTER_BUILD,copy)
endif

portaudio-package: portaudio-stage
	# portaudio.mk Package Structure
	rm -rf $(BUILD_DIST)/libportaudio{2,cpp0,19-dev}
	mkdir -p $(BUILD_DIST)/libportaudio{2,cpp0,19-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# portaudio.mk Prep libportaudio2
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libportaudio.2.dylib $(BUILD_DIST)/libportaudio2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# portaudio.mk Prep libportaudiocpp0
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libportaudiocpp.0.dylib $(BUILD_DIST)/libportaudiocpp0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# portaudio.mk Prep libportaudio19-dev
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libportaudio{cpp,}.{dylib,a},pkgconfig} $(BUILD_DIST)/libportaudio19-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libportaudio19-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# portaudio.mk Sign
	$(call SIGN,libportaudio2,general.xml)
	$(call SIGN,libportaudiocpp0,general.xml)

	# portaudio.mk Make .debs
	$(call PACK,libportaudio2,DEB_PORTAUDIO_V)
	$(call PACK,libportaudiocpp0,DEB_PORTAUDIO_V)
	$(call PACK,libportaudio19-dev,DEB_PORTAUDIO_V)

	# portaudio.mk Build cleanup
	rm -rf $(BUILD_DIST)/libportaudio{2,cpp0,19-dev}

.PHONY: portaudio portaudio-package
