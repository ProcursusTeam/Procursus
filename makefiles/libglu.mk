ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libglu
LIBGLU_VERSION := 9.0.1
DEB_LIBGLU_V   ?= $(LIBGLU_VERSION)

libglu-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/libglu-$(LIBGLU_VERSION).tar.xz, \
		ftp://ftp.freedesktop.org/pub/mesa/glu/glu-$(LIBGLU_VERSION).tar.xz)
	$(call EXTRACT_TAR,libglu-$(LIBGLU_VERSION).tar.xz,glu-$(LIBGLU_VERSION),libglu)
	sed -i 's/-keep_private_externs -nostdlib/-keep_private_externs $(PLATFORM_VERSION_MIN) -arch $(MEMO_ARCH) -nostdlib/g' $(BUILD_WORK)/libglu/configure
	sed -i 's|Internal convenience typedefs|*/\nGLAPI void GLAPIENTRY gluDeleteNurbsTessellatorEXT(GLUnurbsObj *r);\nGLAPI void GLAPIENTRY glu_LOD_eval_list(GLUnurbs *nurb, int level);\n/*|g' $(BUILD_WORK)/libglu/include/GL/glu.h
	sed -i 's|#define gluNurbsCallbackDataEXT mgluNurbsCallbackDataEXT|#define gluNurbsCallbackDataEXT  mgluNurbsCallbackDataEXT\n#define gluDeleteNurbsTessellatorEXT mgluDeleteNurbsTessellatorEXT\n#define glu_LOD_eval_list mglu_LOD_eval_list|g' $(BUILD_WORK)/libglu/include/GL/glu_mangle.h

ifneq ($(wildcard $(BUILD_WORK)/libglu/.build_complete),)
libglu:
	@echo "Using previously built libglu."
else
libglu: libglu-setup mesa
	cd $(BUILD_WORK)/libglu && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libglu
	+$(MAKE) -C $(BUILD_WORK)/libglu install \
		DESTDIR=$(BUILD_STAGE)/libglu
	$(call AFTER_BUILD,copy)
endif

libglu-package: libglu-stage
	# libglu.mk Package Structure
	rm -rf $(BUILD_DIST)/libglu1-mesa{,-dev}
	mkdir -p $(BUILD_DIST)/libglu1-mesa{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libglu.mk Prep libglu1-mesa
	cp -a $(BUILD_STAGE)/libglu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGLU.1.dylib $(BUILD_DIST)/libglu1-mesa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libglu.mk Prep libglu1-mesa-dev
	cp -a $(BUILD_STAGE)/libglu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libGLU.1.dylib) $(BUILD_DIST)/libglu1-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libglu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libglu1-mesa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libglu.mk Sign
	$(call SIGN,libglu1-mesa,general.xml)

	# libglu.mk Make .debs
	$(call PACK,libglu1-mesa,DEB_LIBGLU_V)
	$(call PACK,libglu1-mesa-dev,DEB_LIBGLU_V)

	# libglu.mk Build cleanup
	rm -rf $(BUILD_DIST)/libglu1-mesa{,-dev}

.PHONY: libglu libglu-package
