ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += wasmer
WASMER_VERSION := 2.0.0
DEB_WASMER_V   ?= $(WASMER_VERSION)

wasmer-setup: setup
	$(call GITHUB_ARCHIVE,wasmerio,wasmer,$(WASMER_VERSION),v$(WASMER_VERSION))
	$(call EXTRACT_TAR,wasmer-$(WASMER_VERSION).tar.gz,wasmer-$(WASMER_VERSION),wasmer)
	$(call DO_PATCH,wasmer,wasmer,-p1)
	mkdir -p $(BUILD_STAGE)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig}

ifneq ($(wildcard $(BUILD_WORK)/wasmer/.build_complete),)
wasmer:
	@echo "Using previously built wasmer."
else
wasmer: wasmer-setup
	unset CFLAGS && $(DEFAULT_RUST_FLAGS) cargo build \
		--manifest-path="$(BUILD_WORK)/wasmer/lib/cli/Cargo.toml" \
		--release \
		--target=$(RUST_TARGET) \
		--features="cranelift" \
		--bin wasmer
	unset CFLAGS && $(DEFAULT_RUST_FLAGS) cargo build \
		--manifest-path="$(BUILD_WORK)/wasmer/lib/c-api/Cargo.toml" \
		--release \
		--target=$(RUST_TARGET) \
		--features="cranelift,dylib,staticlib"
	$(INSTALL) -Dm755 $(BUILD_WORK)/wasmer/target/$(RUST_TARGET)/release/wasmer $(BUILD_STAGE)/wasmer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/wasmer
	$(INSTALL) -Dm755 $(BUILD_WORK)/wasmer/target/$(RUST_TARGET)/release/libwasmer_c_api.dylib $(BUILD_STAGE)/libwasmer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwasmer.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwasmer.dylib $(BUILD_STAGE)/libwasmer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwasmer.dylib
	$(INSTALL) -Dm644 $(BUILD_WORK)/wasmer/lib/c-api/*.h $(BUILD_STAGE)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(INSTALL) -Dm755 $(BUILD_WORK)/wasmer/target/$(RUST_TARGET)/release/libwasmer_c_api.a $(BUILD_STAGE)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwasmer.a
	$(INSTALL) -Dm644 $(BUILD_MISC)/wasmer/wasmer.pc $(BUILD_STAGE)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/wasmer.pc
	$(SED) -i 's|prefix=|prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/wasmer.pc
	$(SED) -i 's/Version:/Version: $(WASMER_VERSION)/g' \
		$(BUILD_STAGE)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/wasmer.pc
	touch $(BUILD_WORK)/wasmer/.build_complete
endif

wasmer-package: wasmer-stage
	# wasmer.mk Package Structure
	rm -rf $(BUILD_DIST)/wasmer $(BUILD_DIST)/libwasmer{,-dev}
	mkdir -p $(BUILD_DIST)/wasmer $(BUILD_DIST)/libwasmer{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# wasmer.mk Prep wasmer
	cp -a $(BUILD_STAGE)/wasmer $(BUILD_DIST)

	# wasmer.mk Prep libwasmer
	cp -a $(BUILD_STAGE)/libwasmer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwasmer.dylib $(BUILD_DIST)/libwasmer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwasmer.dylib

	# wasmer.mk Prep libwasmer-dev
	cp -a $(BUILD_STAGE)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} $(BUILD_DIST)/libwasmer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# wasmer.mk Sign
	$(call SIGN,wasmer,general.xml)
	$(call SIGN,libwasmer,general.xml)

	# wasmer.mk Make .debs
	$(call PACK,wasmer,DEB_WASMER_V)
	$(call PACK,libwasmer,DEB_WASMER_V)
	$(call PACK,libwasmer-dev,DEB_WASMER_V)

	# wasmer.mk Build cleanup
	rm -rf $(BUILD_DIST)/wasmer

.PHONY: wasmer wasmer-package
