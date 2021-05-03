ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS        += libiosexec
LIBIOSEXEC_VERSION := 1.0.3
SONAME			   := 1
DEB_LIBIOSEXEC_V   ?= $(LIBIOSEXEC_VERSION)

libiosexec-setup: setup
		$(call GITHUB_ARCHIVE,ProcursusTeam,libiosexec,$(LIBIOSEXEC_VERSION),$(LIBIOSEXEC_VERSION))
		$(call EXTRACT_TAR,libiosexec-$(LIBIOSEXEC_VERSION).tar.gz,libiosexec-$(LIBIOSEXEC_VERSION),libiosexec)

ifneq ($(wildcard $(BUILD_WORK)/libiosexec/.build_complete),)
libiosexec:
	@echo "Using previously built libiosexec."
else
libiosexec: libiosexec-setup
	mkdir -p $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	$(MAKE) -C $(BUILD_WORK)/libiosexec

	$(CP) -a $(BUILD_WORK)/libiosexec/libiosexec.$(SONAME).dylib $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	$(LN) -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.$(SONAME).dylib $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.dylib 

	$(CP) -a $(BUILD_WORK)/libiosexec/libiosexec.$(SONAME).dylib $(BUILD_BASE)/usr/lib/
	$(LN) -s $(BUILD_BASE)/usr/lib/libiosexec.$(SONAME).dylib $(BUILD_BASE)/usr/lib/libiosexec.dylib

	touch $(BUILD_WORK)/libiosexec/.build_complete
endif

libiosexec-package: libiosexec-stage
	# libiosexec.mk Package Structure
	rm -rf $(BUILD_DIST)/libiosexec

	# libiosexec.mk Prep libiosexec
	cp -a $(BUILD_STAGE)/libiosexec $(BUILD_DIST)

	# libiosexec.mk Make .debs
	$(call PACK,libiosexec,DEB_LIBIOSEXEC_V)

	# libiosexec.mk Build cleanup
	rm -rf $(BUILD_DIST)/libiosexec

.PHONY: libiosexec libiosexec-package

endif
