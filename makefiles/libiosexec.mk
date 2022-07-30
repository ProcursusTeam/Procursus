ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS      += libiosexec
LIBIOSEXEC_VERSION := 1.2.2
DEB_LIBIOSEXEC_V   ?= $(LIBIOSEXEC_VERSION)

ifneq (,$(findstring rootless,$(MEMO_TARGET)))
LIBIOSEXEC_FLAGS   := SHEBANG_REDIRECT_PATH="$(MEMO_PREFIX)" \
		      LIBIOSEXEC_PREFIXED_ROOT=1
else
LIBIOSEXEC_FLAGS   := LIBIOSEXEC_PREFIXED_ROOT=0
endif

libiosexec-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,libiosexec,$(LIBIOSEXEC_VERSION),$(LIBIOSEXEC_VERSION))
	$(call EXTRACT_TAR,libiosexec-$(LIBIOSEXEC_VERSION).tar.gz,libiosexec-$(LIBIOSEXEC_VERSION),libiosexec)

ifneq ($(wildcard $(BUILD_WORK)/libiosexec/.build_complete),)
libiosexec:
	@echo "Using previously built libiosexec."
else
libiosexec: libiosexec-setup
	+$(MAKE) -C $(BUILD_WORK)/libiosexec install \
		DESTDIR=$(BUILD_STAGE)/libiosexec \
		$(LIBIOSEXEC_FLAGS) \
		DEFAULT_INTERPRETER="$(MEMO_PREFIX)/bin/sh"
	$(call AFTER_BUILD)
endif

libiosexec-package: libiosexec-stage
	# libiosexec.mk Package Structure
	rm -rf $(BUILD_DIST)/libiosexec{1,-dev}
	mkdir -p $(BUILD_DIST)/libiosexec{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libiosexec1 Prep libiosexec1
	cp -a $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.1.dylib $(BUILD_DIST)/libiosexec1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libiosexec-dev Prep libiosexec-dev
	cp -a $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libiosexec.1.dylib) $(BUILD_DIST)/libiosexec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libiosexec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libiosexec-1 sign
	$(call SIGN,libiosexec1,general.xml)

	# libiosexec.mk Make .debs
	$(call PACK,libiosexec1,DEB_LIBIOSEXEC_V)
	$(call PACK,libiosexec-dev,DEB_LIBIOSEXEC_V)

	# libiosexec.mk Build cleanup
	rm -rf $(BUILD_DIST)/libiosexec{1,-dev}

.PHONY: libiosexec libiosexec-package

endif
