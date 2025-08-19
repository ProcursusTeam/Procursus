ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1700 ] && echo 1),1)

SUBPROJECTS  += x8A4
X8A4_VERSION := 1.0.2
CHOMA_COMMIT := 2fcc1fc51f6eb778756ccdee3c809bf83a767996
XPF_COMMIT   := 19798b65bd7eb3014261a550e666335aff439156
DEB_X8A4_V   ?= $(X8A4_VERSION)

LIBX8A4_SOVERSION := 1

x8A4-setup: setup
	$(call GITHUB_ARCHIVE,Cryptiiiic,x8A4,$(X8A4_VERSION),v$(X8A4_VERSION))
	$(call EXTRACT_TAR,x8A4-$(X8A4_VERSION).tar.gz,x8A4-$(X8A4_VERSION),x8A4)
	rm -rf $(BUILD_WORK)/x8A4/Lib/{ChOma,XPF} $(BUILD_WORK)/x8A4/Lib/lib{choma,XPF}.a
	$(call GITHUB_ARCHIVE,opa334,ChOma,$(CHOMA_COMMIT),$(CHOMA_COMMIT),ChOma)
	$(call GITHUB_ARCHIVE,opa334,XPF,$(XPF_COMMIT),$(XPF_COMMIT),XPF)
	$(call EXTRACT_TAR,ChOma-$(CHOMA_COMMIT).tar.gz,ChOma-$(CHOMA_COMMIT),x8A4/Lib/ChOma)
	$(call EXTRACT_TAR,XPF-$(XPF_COMMIT).tar.gz,XPF-$(XPF_COMMIT),x8A4/Lib/XPF)
	$(call DO_PATCH,choma,x8A4/Lib/ChOma,-p1)
	$(call DO_PATCH,xpf,x8A4/Lib/XPF,-p1)
	rm -rf $(BUILD_WORK)/x8A4/Lib/XPF/external/ios/include/choma/* $(BUILD_WORK)/x8A4/Lib/XPF/external/ios/lib/libchoma.*
	rm -rf $(BUILD_WORK)/x8A4/Include/XPF/* $(BUILD_WORK)/x8A4/Include/choma/* $(BUILD_WORK)/x8A4/Lib/XPF/external/ios/lib/libchoma.*
	cp -a $(BUILD_WORK)/x8A4/Lib/ChOma/src/*.h $(BUILD_WORK)/x8A4/Lib/XPF/external/ios/include/choma/
	cp -a $(BUILD_WORK)/x8A4/Lib/ChOma/src/*.h $(BUILD_WORK)/x8A4/Include/choma/
	cp -a $(BUILD_WORK)/x8A4/Lib/XPF/src/*.h $(BUILD_WORK)/x8A4/Include/XPF
	mkdir -p $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib,bin}


ifneq ($(wildcard $(BUILD_WORK)/x8A4/.build_complete),)
x8A4:
	@echo "Using previously built x8A4."
else
x8A4: x8A4-setup
	# libchoma.a
	cd $(BUILD_WORK)/x8A4/Lib/ChOma && \
		rm -rf $(BUILD_WORK)/x8A4/Lib/libchoma.a src/*.o; \
		for file in src/*.c; do \
			$(CC) -Isrc $(CFLAGS) -c -o $$file.o $$file; \
		done; \
		ar r $(BUILD_WORK)/x8A4/Lib/libchoma.a src/*o; \
	# libxpf.a
	cd $(BUILD_WORK)/x8A4/Lib/XPF && \
		rm -rf $(BUILD_WORK)/x8A4/Lib/libxpf.a src/*.o; \
		for file in src/*.c; do \
			$(CC) -Iexternal/ios/include $(CFLAGS) -c -o $$file.o $$file; \
		done; \
		ar r $(BUILD_WORK)/x8A4/Lib/libxpf.a src/*o; \
	# x8A4
	cd $(BUILD_WORK)/x8A4 && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DRELEASE=1
	+$(MAKE) -C $(BUILD_WORK)/x8A4
	cp -a $(BUILD_WORK)/x8A4/libx8A4.dylib $(BUILD_WORK)/x8A4/libx8A4.$(LIBX8A4_SOVERSION).dylib $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_WORK)/x8A4/x8A4_CLI $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/x8A4
	cp -a $(BUILD_WORK)/x8A4/Include/x8A4 $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(call AFTER_BUILD,copy)
endif

x8A4-package: x8A4-stage
	# x8A4.mk Package Structure
	rm -rf $(BUILD_DIST)/libx8A4{-$(LIBX8A4_SOVERSION),-dev} $(BUILD_DIST)/x8A4
	mkdir -p $(BUILD_DIST)/libx8A4-$(LIBX8A4_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libx8A4-$(LIBX8A4_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libx8A4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
		$(BUILD_DIST)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# x8A4.mk Prep libx8A4
	cp -a $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libx8A4.$(LIBX8A4_SOVERSION).dylib $(BUILD_DIST)/libx8A4-$(LIBX8A4_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# x8A4.mk Prep libkrw-dev
	cp -a $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libx8A4.dylib $(BUILD_DIST)/libx8A4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/x8A4 $(BUILD_DIST)/libx8A4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# x8A4.mk Prep x8A4
	cp -a $(BUILD_STAGE)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/x8A4 $(BUILD_DIST)/x8A4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# x8A4.mk Sign
	$(call SIGN,libx8A4-$(LIBX8A4_SOVERSION),general.xml)
	$(call SIGN,x8A4,x8A4.xml)

	# x8A4.mk Make .debs
	$(call PACK,libx8a4-$(LIBX8A4_SOVERSION),DEB_X8A4_V)
	$(call PACK,libx8a4-dev,DEB_X8A4_V)
	$(call PACK,x8a4,DEB_X8A4_V)

	# x8A4.mk Build cleanup
	rm -rf $(BUILD_DIST)/libx8A4{-$(LIBX8A4_SOVERSION),-dev} $(BUILD_DIST)/x8A4

.PHONY: x8A4 x8A4-package
endif
endif
