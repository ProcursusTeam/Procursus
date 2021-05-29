ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += x265
X265_SOVERSION := 199
X265_VERSION   := 3.5
DEB_X265_V     ?= $(X265_VERSION)

# aarch64 asm seems broken. try again next version.

x265-setup: setup
	$(call GIT_CLONE,https://bitbucket.org/multicoreware/x265_git.git,$(X265_VERSION),x265)

ifneq ($(wildcard $(BUILD_WORK)/x265/.build_complete),)
x265:
	@echo "Using previously built x265."
else
x265: x265-setup
	mkdir -p $(BUILD_WORK)/x265/{8,10,12}bit
	cd $(BUILD_WORK)/x265/10bit && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DENABLE_ASSEMBLY=OFF \
		-DENABLE_HDR10_PLUS=ON \
		-DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF \
		-DENABLE_SHARED=OFF -DENABLE_CLI=OFF \
		../source
	+$(MAKE) -C $(BUILD_WORK)/x265/10bit
	mv $(BUILD_WORK)/x265/10bit/libx265.a $(BUILD_WORK)/x265/8bit/libx265_main10.a

	cd $(BUILD_WORK)/x265/12bit && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DENABLE_ASSEMBLY=OFF \
		-DMAIN12=ON \
		-DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF \
		-DENABLE_SHARED=OFF -DENABLE_CLI=OFF \
		../source
	+$(MAKE) -C $(BUILD_WORK)/x265/12bit
	mv $(BUILD_WORK)/x265/12bit/libx265.a $(BUILD_WORK)/x265/8bit/libx265_main12.a

	cd $(BUILD_WORK)/x265/8bit && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DENABLE_ASSEMBLY=OFF \
		-DLINKED_10BIT=ON -DLINKED_12BIT=ON \
		-DEXTRA_LINK_FLAGS=-L. \
		-DEXTRA_LIB="x265_main10.a;x265_main12.a" \
		../source
	+$(MAKE) -C $(BUILD_WORK)/x265/8bit
	mv $(BUILD_WORK)/x265/8bit/libx265.a $(BUILD_WORK)/x265/8bit/libx265_main.a

	cd $(BUILD_WORK)/x265/8bit && $(LIBTOOL) -static -o libx265.a \
		libx265_main.a libx265_main10.a libx265_main12.a

	+$(MAKE) -C $(BUILD_WORK)/x265/8bit install \
		DESTDIR=$(BUILD_STAGE)/x265
	+$(MAKE) -C $(BUILD_WORK)/x265/8bit install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/x265/.build_complete
endif

x265-package: x265-stage
	# x265.mk Package Structure
	rm -rf $(BUILD_DIST)/libx265-{$(X265_SOVERSION),dev} $(BUILD_DIST)/x265
	mkdir -p $(BUILD_DIST)/libx265-$(X265_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libx265-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/x265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# x265.mk Prep libx265-$(X265_SOVERSION)
	cp -a $(BUILD_STAGE)/x265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libx265.$(X265_SOVERSION).dylib $(BUILD_DIST)/libx265-$(X265_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# x265.mk Prep libx265-dev
	cp -a $(BUILD_STAGE)/x265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.$(X265_SOVERSION)*) $(BUILD_DIST)/libx265-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/x265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libx265-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# x265.mk Prep x265
	cp -a $(BUILD_STAGE)/x265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/x265 $(BUILD_DIST)/x265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# x265.mk Sign
	$(call SIGN,libx265-$(X265_SOVERSION),general.xml)
	$(call SIGN,x265,general.xml)

	# x265.mk Make .debs
	$(call PACK,libx265-$(X265_SOVERSION),DEB_X265_V)
	$(call PACK,libx265-dev,DEB_X265_V)
	$(call PACK,x265,DEB_X265_V)

	# x265.mk Build cleanup
	rm -rf $(BUILD_DIST)/libx265-{$(X265_SOVERSION),dev} $(BUILD_DIST)/x265

.PHONY: x265 x265-package
