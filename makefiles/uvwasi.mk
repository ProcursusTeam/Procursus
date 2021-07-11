ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += uvwasi
UVWASI_VERSION := 0.0.11
DEB_UVWASI_V   ?= $(UVWASI_VERSION)
UVWASI_SOVER   := 0

uvwasi-setup: setup
	$(call GITHUB_ARCHIVE,nodejs,uvwasi,$(UVWASI_VERSION),v$(UVWASI_VERSION))
	$(call EXTRACT_TAR,uvwasi-$(UVWASI_VERSION).tar.gz,uvwasi-$(UVWASI_VERSION),uvwasi)
	$(call DO_PATCH,uvwasi,uvwasi,-p1)

ifneq ($(wildcard $(BUILD_WORK)/uvwasi/.build_complete),)
uvwasi:
	@echo "Using previously built uvwasi."
else
uvwasi: uvwasi-setup libuv1
	cd $(BUILD_WORK)/uvwasi && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DWITH_SYSTEM_LIBUV=1 \
		.
	+$(MAKE) -C $(BUILD_WORK)/uvwasi

	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/libuvwasi.dylib $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.$(UVWASI_SOVER).dylib

	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/libuvwasi_a.a $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.a
	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/include/uvwasi.h $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/uvwasi.h
	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/include/wasi_serdes.h $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/wasi_serdes.h
	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/include/wasi_types.h $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/wasi_types.h

	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/libuvwasi.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.$(UVWASI_SOVER).dylib

	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/libuvwasi_a.a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.a
	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/include/uvwasi.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/uvwasi.h
	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/include/wasi_serdes.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/wasi_serdes.h
	$(INSTALL) -Dm644 $(BUILD_WORK)/uvwasi/include/wasi_types.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/wasi_types.h

	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.$(UVWASI_SOVER).dylib $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.$(UVWASI_SOVER).dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.$(UVWASI_SOVER).dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.$(UVWASI_SOVER).dylib
	ln -sf libuvwasi.$(UVWASI_SOVER).dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.dylib
	ln -sf libuvwasi.$(UVWASI_SOVER).dylib $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.dylib

	touch $(BUILD_WORK)/uvwasi/.build_complete
endif

uvwasi-package: uvwasi-stage
	# uvwasi.mk Package Structure
	rm -rf $(BUILD_DIST)/libuvwasi{$(UVWASI_SOVER),-dev}
	mkdir -p $(BUILD_DIST)/libuvwasi{$(UVWASI_SOVER),-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# uvwasi.mk Prep libuvwasi$(UVWASI_SOVER)
	cp -a $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.$(UVWASI_SOVER).dylib $(BUILD_DIST)/libuvwasi$(UVWASI_SOVER)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# uvwasi.mk Prep libuvwasi-dev
	cp -a $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libuvwasi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/uvwasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuvwasi.{a,dylib} $(BUILD_DIST)/libuvwasi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# uvwasi.mk Sign
	$(call SIGN,libuvwasi$(UVWASI_SOVER),general.xml)

	# uvwasi.mk Make .debs
	$(call PACK,libuvwasi$(UVWASI_SOVER),DEB_UVWASI_V)
	$(call PACK,libuvwasi-dev,DEB_UVWASI_V)

	# uvwasi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libuvwasi{$(UVWASI_SOVER),-dev}

.PHONY: uvwasi uvwasi-package
