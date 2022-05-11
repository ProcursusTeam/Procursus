ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS      += ossp-uuid
OSSP-UUID_VERSION  := 1.6.2
DEB_OSSP-UUID_V    ?= $(OSSP-UUID_VERSION)-4

ossp-uuid-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/o/ossp-uuid/ossp-uuid_$(OSSP-UUID_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,ossp-uuid_$(OSSP-UUID_VERSION).orig.tar.gz,uuid-$(OSSP-UUID_VERSION),ossp-uuid)
	$(call DO_PATCH,ossp-uuid,ossp-uuid,-p1)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/ossp-uuid
	sed -i 's/-c -s -m/-c -m/g' $(BUILD_WORK)/ossp-uuid/Makefile.in

ifneq ($(wildcard $(BUILD_WORK)/ossp-uuid/.build_complete),)
ossp-uuid:
	@echo "Using previously built ossp-uuid."
else
ossp-uuid: ossp-uuid-setup
	cd $(BUILD_WORK)/ossp-uuid && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		ac_cv_va_copy=yes \
		CC="$(CC) $(CFLAGS)" \
		CXX="$(CXX) $(CXXFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/ossp-uuid
	+$(MAKE) -C $(BUILD_WORK)/ossp-uuid install \
		DESTDIR=$(BUILD_STAGE)/ossp-uuid
	$(call AFTER_BUILD,copy)
endif

ossp-uuid-package: ossp-uuid-stage
	# ossp-uuid.mk Package Structure
	rm -rf $(BUILD_DIST)/ossp-uuid $(BUILD_DIST)/libossp-uuid{16,-dev}
	mkdir -p $(BUILD_DIST)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/libossp-uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1,lib} \
		$(BUILD_DIST)/libossp-uuid16/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ossp-uuid.mk Prep uuid
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uuid $(BUILD_DIST)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/uuid.1.zst $(BUILD_DIST)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# ossp-uuid.mk Prep libossp-uuid16
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libossp-uuid.16.dylib $(BUILD_DIST)/libossp-uuid16/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ossp-uuid.mk Prep libossp-uuid-dev
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libossp-uuid.16.dylib) $(BUILD_DIST)/libossp-uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/uuid-config.1.zst $(BUILD_DIST)/libossp-uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uuid-config $(BUILD_DIST)/libossp-uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libossp-uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/ossp-uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libossp-uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ossp-uuid.mk Sign
	$(call SIGN,uuid,general.xml)
	$(call SIGN,libossp-uuid16,general.xml)

	# ossp-uuid.mk Make .debs
	$(call PACK,uuid,DEB_OSSP-UUID_V)
	$(call PACK,libossp-uuid16,DEB_OSSP-UUID_V)
	$(call PACK,libossp-uuid-dev,DEB_OSSP-UUID_V)

	# ossp-uuid.mk Build cleanup
	rm -rf $(BUILD_DIST)/uuid $(BUILD_DIST)/libossp-uuid{16,-dev}

.PHONY: ossp-uuid ossp-uuid-package
