ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += gcal
GCAL_VERSION := 4.1
DEB_GCAL_V   ?= $(GCAL_VERSION)

gcal-setup: setup
	curl --silent -L -Z --create-dirs -C - --remote-name-all --output-dir$(BUILD_SOURCE) https://ftpmirror.gnu.org/gnu/gcal/gcal-$(GCAL_VERSION).tar.xz
	$(call EXTRACT_TAR,gcal-$(GCAL_VERSION).tar.xz,gcal-$(GCAL_VERSION),gcal)

ifneq ($(wildcard $(BUILD_WORK)/gcal/.build_complete),)
gcal:
	@echo "Using previously built gcal."
else
gcal: gcal-setup ncurses gettext
	cd $(BUILD_WORK)/gcal && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/gcal
	+$(MAKE) -C $(BUILD_WORK)/gcal install \
		DESTDIR=$(BUILD_STAGE)/gcal
	$(call AFTER_BUILD)
endif

gcal-package: gcal-stage
	# gcal.mk Package Structure
	rm -rf $(BUILD_DIST)/gcal{,-common}
	mkdir -p $(BUILD_DIST)/gcal{,-common}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# gcal.mk Prep gcal
	cp -a $(BUILD_STAGE)/gcal/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/gcal/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# gcal.mk Prep gcal-common
	cp -a $(BUILD_STAGE)/gcal/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/gcal-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# gcal.mk Sign
	$(call SIGN,gcal,general.xml)
	
	# gcal.mk Make .debs
	$(call PACK,gcal,DEB_GCAL_V)
	$(call PACK,gcal-common,DEB_GCAL_V)
	
	# gcal.mk Build cleanup
	rm -rf $(BUILD_DIST)/gcal{,-common}

.PHONY: gcal gcal-package
