ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += mono
MONO_VERSION    := 6.12.0.122
DEB_MONO_V      ?= $(MONO_VERSION)

mono-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.mono-project.com/sources/mono/mono-$(MONO_VERSION).tar.xz
	if [ ! -d $(BUILD_WORK)/mono ]; then mkdir $(BUILD_WORK)/mono && $(TAR) -xf $(BUILD_SOURCE)/mono-$(MONO_VERSION).tar.xz -C $(BUILD_WORK)/mono --strip-components 1; fi
	
	mkdir -p $(BUILD_STAGE)/mono/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(call HAS_COMMAND,mono),1)
mono:
	@echo "Please install mono before proceeding."
else ifneq ($(wildcard $(BUILD_WORK)/mono/.build_complete),)
mono:
	@echo "Using previously built mono."
else
mono: mono-setup

	# The C# code (Mono stdlib)
	cd $(BUILD_WORK)/mono && ./autogen.sh \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--disable-system-aot \
		CFLAGS="-I./libatomic_ops/src" \
		CXXFLAGS="" \
		LDFLAGS="" \
		CPPFLAGS=""

	$(SED) -i 's/$$(CFLAGS)/$$(CFLAGS) -Wl,-undefined,suppress,-flat_namespace/g' $(BUILD_WORK)/mono/mono/native/Makefile
	$(SED) -i 's/$$(BUILD_PLATFORM)/macos/g' $(BUILD_WORK)/mono/mcs/build/rules.make
		
	+$(MAKE) -C $(BUILD_WORK)/mono
	+$(MAKE) -C $(BUILD_WORK)/mono install DESTDIR=$(BUILD_STAGE)/mono
	+$(MAKE) -C $(BUILD_WORK)/mono distclean

	# The native (C) code
	cd $(BUILD_WORK)/mono && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CFLAGS="$(CFLAGS) -I./libatomic_ops/src" \
		LDFLAGS="-framework Foundation"
	
	# This is a bad idea	
	$(SED) -i 's/$$(CFLAGS)/$$(CFLAGS) -Wl,-undefined,suppress,-flat_namespace/g' $(BUILD_WORK)/mono/mono/native/Makefile
	$(SED) -i 's/$$(BUILD_PLATFORM)/macos/g' $(BUILD_WORK)/mono/mcs/build/rules.make
	+$(MAKE) -C $(BUILD_WORK)/mono
	+$(MAKE) -C $(BUILD_WORK)/mono/mcs/jay
		
	+$(MAKE) -C $(BUILD_WORK)/mono install DESTDIR=$(BUILD_STAGE)/mono
	$(CP) $(BUILD_WORK)/mono/mcs/jay/jay $(BUILD_STAGE)/mono/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	touch $(BUILD_WORK)/mono/.build_complete
endif

mono-package: mono-stage
	# mono.mk Package Structure
	mkdir -p $(BUILD_DIST)/mono/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/mono-jay/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# mono.mk Prep mono
	$(CP) -af $(BUILD_STAGE)/mono/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/* $(BUILD_DIST)/mono/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	rm -f $(BUILD_DIST)/mono/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jay

	# mono.mk Prep mono-jay
	$(CP) -af $(BUILD_STAGE)/mono/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jay $(BUILD_DIST)/mono-jay/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# mono.mk Sign
	$(call SIGN,mono,qemu-ios.xml)
	$(call SIGN,mono-jay,qemu-ios.xml)
	
	# mono.mk Make .debs
	$(call PACK,mono,DEB_MONO_V)
	$(call PACK,mono-jay,DEB_MONO_V)
	
	# mono.mk Build cleanup
	rm -rf $(BUILD_DIST)/mono{-jay} 

.PHONY: mono mono-package
