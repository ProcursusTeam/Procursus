ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libglu
LIBGLU_VERSION := 9.0.1
DEB_LIBGLU_V   ?= $(LIBGLU_VERSION)

libglu-setup: setup
	-[ ! -f $(BUILD_SOURCE)/libglu-$(LIBGLU_VERSION).tar.xz ] && \
			wget -q -nc -O$(BUILD_SOURCE)/libglu-$(LIBGLU_VERSION).tar.xz \
				ftp://ftp.freedesktop.org/pub/mesa/glu/glu-$(LIBGLU_VERSION).tar.xz
	$(call EXTRACT_TAR,libglu-$(LIBGLU_VERSION).tar.xz,glu-$(LIBGLU_VERSION),libglu)

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
	+$(MAKE) -C $(BUILD_WORK)/libglu install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libglu/.build_complete
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
