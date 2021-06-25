ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += @pkg@
@PKG@_VERSION := @PKG_VERSION@
DEB_@PKG@_V   ?= $(@PKG@_VERSION)

@pkg@-setup: setup
@download@
	$(call EXTRACT_TAR,@pkg@-$(@PKG@_VERSION).tar.@compression@,@pkg@-$(@PKG@_VERSION),@pkg@)
	$(call DO_PATCH,@pkg@,@pkg@,-p1)
	mkdir -p $(BUILD_WORK)/@pkg@/build
	echo -e "[host_machine]\n \
	system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/@pkg@/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/@pkg@/.build_complete),)
@pkg@:
	@echo "Using previously built @pkg@."
else
@pkg@: @pkg@-setup
	cd $(BUILD_WORK)/@pkg@/build && meson \
		--cross-file cross.txt \
		..
	+ninja -C $(BUILD_WORK)/@pkg@/build
	+ninja -C $(BUILD_WORK)/@pkg@/build install \
		DESTDIR="$(BUILD_STAGE)/@pkg@"
	touch $(BUILD_WORK)/@pkg@/.build_complete
endif

@pkg@-package: @pkg@-stage
	# @pkg@.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@
	
	# @pkg@.mk Prep @pkg@
	cp -a $(BUILD_STAGE)/@pkg@ $(BUILD_DIST)
	
	# @pkg@.mk Sign
	$(call SIGN,@pkg@,general.xml)
	
	# @pkg@.mk Make .debs
	$(call PACK,@pkg@,DEB_@PKG@_V)
	
	# @pkg@.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@

.PHONY: @pkg@ @pkg@-package
