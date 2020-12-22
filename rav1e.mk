ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += rav1e
RAV1E_VERSION := 0.3.4
DEB_RAV1E_V   ?= $(RAV1E_VERSION)-1

rav1e-setup: setup
ifeq (, $(shell which cargo-cbuild))
	$(error "No cargo-cbuild in PATH, please run cargo install cargo-c")
endif

	-[ ! -f "$(BUILD_SOURCE)/rav1e-$(RAV1E_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/rav1e-$(RAV1E_VERSION).tar.gz https://github.com/xiph/rav1e/archive/v$(RAV1E_VERSION).tar.gz
	$(call EXTRACT_TAR,rav1e-$(RAV1E_VERSION).tar.gz,rav1e-$(RAV1E_VERSION),rav1e)
	$(call DO_PATCH,rav1e,rav1e,-p1)

ifneq ($(wildcard $(BUILD_WORK)/rav1e/.build_complete),)
rav1e:
	@echo "Using previously built rav1e."
else
rav1e: rav1e-setup aom dav1d
	cd $(BUILD_WORK)/rav1e && cargo update
	cd $(BUILD_WORK)/rav1e && SDKROOT="$(TARGET_SYSROOT)" cargo \
		build \
		--release \
		--target=$(RUST_TARGET)
	cd $(BUILD_WORK)/rav1e && SDKROOT="$(TARGET_SYSROOT)" cargo \
		cbuild \
		--release \
		--prefix=/usr \
		--target=$(RUST_TARGET)

	$(GINSTALL) -Dm755 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e $(BUILD_STAGE)/rav1e/usr/bin/rav1e

	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.dylib $(BUILD_STAGE)/rav1e/usr/lib/librav1e.0.dylib

	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.a $(BUILD_STAGE)/rav1e/usr/lib/librav1e.a
	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.pc $(BUILD_STAGE)/rav1e/usr/lib/pkgconfig/rav1e.pc
	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.h $(BUILD_STAGE)/rav1e/usr/include/rav1e.h


	$(GINSTALL) -Dm755 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e $(BUILD_BASE)/usr/bin/rav1e

	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.dylib $(BUILD_BASE)/usr/lib/librav1e.0.dylib

	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/librav1e.a $(BUILD_BASE)/usr/lib/librav1e.a
	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.pc $(BUILD_BASE)/usr/lib/pkgconfig/rav1e.pc
	$(GINSTALL) -Dm644 $(BUILD_WORK)/rav1e/target/$(RUST_TARGET)/release/rav1e.h $(BUILD_BASE)/usr/include/rav1e.h
	
	$(I_N_T) -id /usr/lib/librav1e.0.dylib $(BUILD_STAGE)/rav1e/usr/lib/librav1e.0.dylib
	$(I_N_T) -id /usr/lib/librav1e.0.dylib $(BUILD_BASE)/usr/lib/librav1e.0.dylib
	ln -sf librav1e.0.dylib $(BUILD_BASE)/usr/lib/librav1e.dylib

	touch $(BUILD_WORK)/rav1e/.build_complete
endif

rav1e-package: rav1e-stage
	# rav1e.mk Package Structure
	rm -rf $(BUILD_DIST)/{rav1e,librav1e,librav1e-dev}
	mkdir -p \
		$(BUILD_DIST)/rav1e/usr \
		$(BUILD_DIST)/librav1e0/usr/lib \
		$(BUILD_DIST)/librav1e-dev/usr/lib

	# rav1e.mk Prep rav1e
	cp -a $(BUILD_STAGE)/rav1e/usr/bin $(BUILD_DIST)/rav1e/usr

	# rav1e.mk Prep librav1e0
	cp -a $(BUILD_STAGE)/rav1e/usr/lib/librav1e.0.dylib $(BUILD_DIST)/librav1e0/usr/lib

	# rav1e.mk Prep librav1e-dev
	cp -a $(BUILD_STAGE)/rav1e/usr/lib/librav1e.a $(BUILD_DIST)/librav1e-dev/usr/lib
	cp -a $(BUILD_STAGE)/rav1e/usr/lib/pkgconfig $(BUILD_DIST)/librav1e-dev/usr/lib
	cp -a $(BUILD_STAGE)/rav1e/usr/include $(BUILD_DIST)/librav1e-dev/usr
	ln -s librav1e.0.dylib $(BUILD_DIST)/librav1e-dev/usr/lib/librav1e.dylib

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
