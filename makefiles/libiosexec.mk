ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS      += libiosexec
LIBIOSEXEC_COMMIT  := 0b53c7cacd249e3dd9b55dba45b90fc543a4a603
LIBIOSEXEC_SOVER   := 1
DEB_LIBIOSEXEC_V   ?= 1.0.20~git20220309.$(shell echo $(LIBIOSEXEC_COMMIT) | cut -c -7)

ifneq (,$(findstring rootless,$(MEMO_TARGET)))
LIBIOSEXEC_FLAGS   := SHEBANG_REDIRECT_PATH="$(MEMO_PREFIX)" \
		      LIBIOSEXEC_PREFIXED_ROOT=1 \
		      DEFAULT_INTERPRETER="$(MEMO_PREFIX)/bin/sh"
else
LIBIOSEXEC_FLAGS   := LIBIOSEXEC_PREFIXED_ROOT=0 \
		      DEFAULT_INTERPRETER="$(MEMO_PREFIX)/bin/sh"
endif

libiosexec-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,libiosexec,$(LIBIOSEXEC_COMMIT),$(LIBIOSEXEC_COMMIT))
	$(call EXTRACT_TAR,libiosexec-$(LIBIOSEXEC_COMMIT).tar.gz,libiosexec-$(LIBIOSEXEC_COMMIT),libiosexec)

ifneq ($(wildcard $(BUILD_WORK)/libiosexec/.build_complete),)
libiosexec:
	@echo "Using previously built libiosexec."
else
libiosexec: libiosexec-setup
	+$(MAKE) -C $(BUILD_WORK)/libiosexec install \
		DESTDIR=$(BUILD_STAGE)/libiosexec \
		$(LIBIOSEXEC_FLAGS)
	$(call AFTER_BUILD)
endif

libiosexec-package: libiosexec-stage
	# libiosexec.mk Package Structure
	rm -rf $(BUILD_DIST)/libiosexec{$(LIBIOSEXEC_SOVER),-dev}
	mkdir -p $(BUILD_DIST)/libiosexec{$(LIBIOSEXEC_SOVER),-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libiosexec1 Prep libiosexec$(LIBIOSEXEC_SOVER)
	cp -a $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.$(LIBIOSEXEC_SOVER).dylib $(BUILD_DIST)/libiosexec$(LIBIOSEXEC_SOVER)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libiosexec-dev Prep libiosexec-dev
	cp -a $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libiosexec.$(LIBIOSEXEC_SOVER).dylib) $(BUILD_DIST)/libiosexec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libiosexec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libiosexec-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libiosexec-1 sign
	$(call SIGN,libiosexec1,general.xml)

	# libiosexec.mk Make .debs
	$(call PACK,libiosexec1,DEB_LIBIOSEXEC_V)
	$(call PACK,libiosexec-dev,DEB_LIBIOSEXEC_V)

	# libiosexec.mk Build cleanup
	rm -rf $(BUILD_DIST)/libiosexec{$(LIBIOSEXEC_SOVER),-dev}

.PHONY: libiosexec libiosexec-package

endif
