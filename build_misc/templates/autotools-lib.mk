ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += @pkg@
@PKG@_VERSION := @PKG_VERSION@
DEB_@PKG@_V   ?= $(@PKG@_VERSION)

@pkg@-setup: setup
@download@
	$(call EXTRACT_TAR,@pkg@-$(@PKG@_VERSION).tar.@compression@,@pkg@-$(@PKG@_VERSION),@pkg@)
	#$(call DO_PATCH,@pkg@,@pkg@,-p1)

ifneq ($(wildcard $(BUILD_WORK)/@pkg@/.build_complete),)
@pkg@:
	@echo "Using previously built @pkg@."
else
@pkg@: @pkg@-setup
	cd $(BUILD_WORK)/@pkg@ && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/@pkg@
	+$(MAKE) -C $(BUILD_WORK)/@pkg@ install \
		DESTDIR=$(BUILD_STAGE)/@pkg@
	+$(MAKE) -C $(BUILD_WORK)/@pkg@ install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/@pkg@/.build_complete
endif

@pkg@-package: @pkg@-stage
	# @pkg@.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@{@SOVER@,-dev}
	mkdir -p $(BUILD_DIST)/@pkg@{@SOVER@,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# @pkg@.mk Prep @pkg@@SOVER@
	cp -a $(BUILD_STAGE)/@pkg@/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/@pkg@.@SOVER@.dylib $(BUILD_DIST)/@pkg@@SOVER@/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# @pkg@.mk Prep @pkg@-dev
	cp -a $(BUILD_STAGE)/@pkg@/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/@pkg@-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/@pkg@/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,@pkg@.{dylib,a}} $(BUILD_DIST)/@pkg@-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# @pkg@.mk Sign
	$(call SIGN,@pkg@@SOVER@,general.xml)
	
	# @pkg@.mk Make .debs
	$(call PACK,@pkg@@SOVER@,DEB_@PKG@_V)
	$(call PACK,@pkg@-dev,DEB_@PKG@_V)
	
	# @pkg@.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@{@SOVER@,-dev}

.PHONY: @pkg@ @pkg@-package
