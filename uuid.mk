ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += uuid
UUID_VERSION  := 1.6.2
DEB_UUID_V    ?= $(UUID_VERSION)-3

uuid-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/o/ossp-uuid/ossp-uuid_$(UUID_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,ossp-uuid_$(UUID_VERSION).orig.tar.gz,uuid-$(UUID_VERSION),uuid)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/uuid
	$(SED) -i 's/-c -s -m/-c -m/g' $(BUILD_WORK)/uuid/Makefile.in

ifneq ($(wildcard $(BUILD_WORK)/uuid/.build_complete),)
uuid:
	@echo "Using previously built uuid."
else
uuid: uuid-setup
	cd $(BUILD_WORK)/uuid && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		ac_cv_va_copy=yes \
		CC="$(CC) $(CFLAGS)" \
		CXX="$(CXX) $(CXXFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/uuid
	+$(MAKE) -C $(BUILD_WORK)/uuid install \
		DESTDIR=$(BUILD_STAGE)/uuid
	+$(MAKE) -C $(BUILD_WORK)/uuid install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/uuid/.build_complete
endif

uuid-package: uuid-stage
	# uuid.mk Package Structure
	rm -rf $(BUILD_DIST)/uuid $(BUILD_DIST)/libuuid{16,-dev}
	mkdir -p $(BUILD_DIST)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/libuuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1,lib} \
		$(BUILD_DIST)/libuuid16/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# uuid.mk Prep uuid
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uuid $(BUILD_DIST)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/uuid.1 $(BUILD_DIST)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# uuid.mk Prep libuuid16
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuuid.16.dylib $(BUILD_DIST)/libuuid16/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# uuid.mk Prep libuuid-dev
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libuuid.16.dylib) $(BUILD_DIST)/libuuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/uuid-config.1 $(BUILD_DIST)/libuuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uuid-config $(BUILD_DIST)/libuuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libuuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/uuid/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libuuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# uuid.mk Sign
	$(call SIGN,uuid,general.xml)
	$(call SIGN,libuuid16,general.xml)

	# uuid.mk Make .debs
	$(call PACK,uuid,DEB_UUID_V)
	$(call PACK,libuuid16,DEB_UUID_V)
	$(call PACK,libuuid-dev,DEB_UUID_V)

	# uuid.mk Build cleanup
	rm -rf $(BUILD_DIST)/uuid $(BUILD_DIST)/libuuid{16,-dev}

.PHONY: uuid uuid-package
