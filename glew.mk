ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += glew
GLEW_VERSION := 2.2.0
DEB_GLEW_V   ?= $(GLEW_VERSION)

glew-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/project/glew/glew/$(GLEW_VERSION)/glew-$(GLEW_VERSION).tgz
	$(call EXTRACT_TAR,glew-$(GLEW_VERSION).tgz,glew-$(GLEW_VERSION),glew)
	$(SED) -i -e s/GLEW_DEST/GLEW_PREFIX/ \
		-e 's/(LIB.SHARED)/(LIB.SONAME)/' $(BUILD_WORK)/glew/config/Makefile.darwin

ifneq ($(wildcard $(BUILD_WORK)/glew/.build_complete),)
glew:
	@echo "Using previously built glew."
else
glew: glew-setup mesa libx11
	+$(MAKE) -C $(BUILD_WORK)/glew all install \
		SYSTEM=darwin \
		GLEW_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		GLEW_DEST=$(BUILD_STAGE)/glew/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CFLAGS.EXTRA="$(CFLAGS) -DGLEW_APPLE_GLX" \
		LDFLAGS.EXTRA="$(LDFLAGS)" \
		LN="ln -sf" \
		GLEW_APPLE_GLX=yes
	+$(MAKE) -C $(BUILD_WORK)/glew all install \
		SYSTEM=darwin \
		GLEW_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		GLEW_DEST=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CFLAGS.EXTRA="$(CFLAGS) -DGLEW_APPLE_GLX" \
		LDFLAGS.EXTRA="$(LDFLAGS)" \
		LN="ln -sf" \
		GLEW_APPLE_GLX=yes
	touch $(BUILD_WORK)/glew/.build_complete
endif

glew-package: glew-stage
	# glew.mk Package Structure
	rm -rf $(BUILD_DIST)/libglew{2.2,-dev}
	mkdir -p $(BUILD_DIST)/libglew{2.2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# glew.mk Prep libglew2.2
	cp -a $(BUILD_STAGE)/glew/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGLEW.2.2*.dylib $(BUILD_DIST)/libglew2.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# glew.mk Prep libglew-dev
	cp -a $(BUILD_STAGE)/glew/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libGLEW.2.2*.dylib) $(BUILD_DIST)/libglew-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/glew/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libglew-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# glew.mk Sign
	$(call SIGN,libglew2.2,general.xml)
	
	# glew.mk Make .debs
	$(call PACK,libglew2.2,DEB_GLEW_V)
	$(call PACK,libglew-dev,DEB_GLEW_V)
	
	# glew.mk Build cleanup
	rm -rf $(BUILD_DIST)/libglew{2.2,-dev}

.PHONY: glew glew-package
