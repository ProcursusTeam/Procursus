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

ifneq ($(wildcard $(BUILD_WORK)/@pkg@/.build_complete),)
@pkg@:
	@echo "Using previously built @pkg@."
else
@pkg@: @pkg@-setup perl
	cd $(BUILD_WORK)/@pkg@ && $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl Makefile.PL \
		$(DEFAULT_PERL_MAKE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/@pkg@
	+$(MAKE) -C $(BUILD_WORK)/@pkg@ install \
		DESTDIR="$(BUILD_STAGE)/@pkg@"
	touch $(BUILD_WORK)/@pkg@/.build_complete
endif

@pkg@-package: @pkg@-stage
	# @pkg@.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@
	
	# @pkg@.mk Prep @pkg@
	cp -a $(BUILD_STAGE)/@pkg@ $(BUILD_DIST)
	
	# @pkg@.mk Make .debs
	$(call PACK,@pkg@,DEB_@PKG@_V)
	
	# @pkg@.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@

.PHONY: @pkg@ @pkg@-package
