ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += x264
X264_SOVERSION := 164
X264_COMMIT    := baee400fa9ced6f5481a728138fed6e867b0ff7f
X264_VERSION   := 0.$(X264_SOVERSION).3095+git$(shell echo $(X264_COMMIT) | cut -c -7)
DEB_X264_V     ?= $(X264_VERSION)

ifneq (,$(findstring arm64,$(MEMO_TARGET)))
X264_CONFIGURE_ARGS += --extra-asflags='$(CFLAGS)'
endif

x264-setup: setup
#	Clones latest from the stable branch. Update version/commit on compile.
	$(call GIT_CLONE,https://code.videolan.org/videolan/x264.git,stable,x264)

ifneq ($(wildcard $(BUILD_WORK)/x264/.build_complete),)
x264:
	@echo "Using previously built x264."
else
x264: x264-setup
	cd $(BUILD_WORK)/x264 && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-shared \
		--enable-static \
		--enable-strip \
		--system-libx264 \
		--enable-lto \
		$(X264_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/x264
	+$(MAKE) -C $(BUILD_WORK)/x264 install \
		DESTDIR=$(BUILD_STAGE)/x264
	$(call AFTER_BUILD,copy)
endif

x264-package: x264-stage
	# x264.mk Package Structure
	rm -rf $(BUILD_DIST)/libx264-{$(X264_SOVERSION),dev} $(BUILD_DIST)/x264
	mkdir -p $(BUILD_DIST)/libx264-$(X264_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libx264-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/x264/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# x264.mk Prep libx264-$(X264_SOVERSION)
	cp -a $(BUILD_STAGE)/x264/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libx264.$(X264_SOVERSION).dylib $(BUILD_DIST)/libx264-$(X264_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# x264.mk Prep libx264-dev
	cp -a $(BUILD_STAGE)/x264/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.$(X264_SOVERSION)*) $(BUILD_DIST)/libx264-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/x264/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libx264-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# x264.mk Prep x264
	cp -a $(BUILD_STAGE)/x264/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/x264 $(BUILD_DIST)/x264/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# x264.mk Sign
	$(call SIGN,libx264-$(X264_SOVERSION),general.xml)
	$(call SIGN,x264,general.xml)

	# x264.mk Make .debs
	$(call PACK,libx264-$(X264_SOVERSION),DEB_X264_V)
	$(call PACK,libx264-dev,DEB_X264_V)
	$(call PACK,x264,DEB_X264_V)

	# x264.mk Build cleanup
	rm -rf $(BUILD_DIST)/libx264-{$(X264_SOVERSION),dev} $(BUILD_DIST)/x264

.PHONY: x264 x264-package
