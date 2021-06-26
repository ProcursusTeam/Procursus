ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += rav1e
RAV1E_VERSION := 0.4.1
DEB_RAV1E_V   ?= $(RAV1E_VERSION)

rav1e-setup: setup
	$(call GITHUB_ARCHIVE,xiph,rav1e,$(RAV1E_VERSION),v$(RAV1E_VERSION))
	$(call EXTRACT_TAR,rav1e-$(RAV1E_VERSION).tar.gz,rav1e-$(RAV1E_VERSION),rav1e)
	$(call DO_PATCH,rav1e,rav1e,-p1)

ifneq ($(wildcard $(BUILD_WORK)/rav1e/.build_complete),)
rav1e:
	@echo "Using previously built rav1e."
else
rav1e: rav1e-setup aom dav1d
	cd $(BUILD_WORK)/rav1e && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	cd $(BUILD_WORK)/rav1e && $(DEFAULT_RUST_FLAGS) cargo cbuild \
		--release \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--target=$(RUST_TARGET) \
		--library-type staticlib

	$(INSTALL) -Dm755 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rav1e

	$(CC) $(CFLAGS) -fPIC -install_name $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.0.dylib -shared -o $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.0.dylib $(LDFLAGS) -Wl,-force_load $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.a -framework Security -lobjc

	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.0.dylib $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.0.dylib

	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.a $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.a
	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.pc $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/rav1e.pc
	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.h $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/rav1e.h

	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.0.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.0.dylib

	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.a
	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.pc $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/rav1e.pc
	$(INSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/rav1e.h

	ln -sf librav1e.0.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.dylib

	touch $(BUILD_WORK)/rav1e/.build_complete
endif

rav1e-package: rav1e-stage
	# rav1e.mk Package Structure
	rm -rf $(BUILD_DIST)/{rav1e,librav1e0,librav1e-dev}
	mkdir -p \
		$(BUILD_DIST)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/librav1e0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/librav1e-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# rav1e.mk Prep rav1e
	cp -a $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rav1e.mk Prep librav1e0
	cp -a $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.0.dylib $(BUILD_DIST)/librav1e0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# rav1e.mk Prep librav1e-dev
	cp -a $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.a $(BUILD_DIST)/librav1e-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/librav1e-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/rav1e/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/librav1e-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	ln -s librav1e.0.dylib $(BUILD_DIST)/librav1e-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librav1e.dylib

	# rav1e.mk Sign
	$(call SIGN,rav1e,general.xml)
	$(call SIGN,librav1e0,general.xml)

	# rav1e.mk Make .debs
	$(call PACK,rav1e,DEB_RAV1E_V)
	$(call PACK,librav1e0,DEB_RAV1E_V)
	$(call PACK,librav1e-dev,DEB_RAV1E_V)

	# rav1e.mk Build cleanup
	rm -rf $(BUILD_DIST)/{rav1e,librav1e0,librav1e-dev}

.PHONY: rav1e rav1e-package
