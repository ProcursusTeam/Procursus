ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += wptc-track
WPTC_TRACK_VERSION := 2020.09.26
DEB_WPTC_TRACK_V   ?= $(WPTC_TRACK_VERSION)

wptc-track-setup: setup
	if [ ! -d "$(BUILD_WORK)/wptc-track" ]; then \
	git clone https://github.com/titoxd/wptc-track "$(BUILD_WORK)/wptc-track"; \
	cd "$(BUILD_WORK)/wptc-track"; \
	git fetch origin; \
	git reset --hard origin/master; \
	git checkout "69bfe15eef70be9da64339eba41de1d00b0a6ec9"; \
	fi
ifneq ($(wildcard $(BUILD_WORK)/wptc-track/.build_complete),)
wptc-track:
	@echo "Using previously built wptc-track."
else
wptc-track: wptc-track-setup pcre cairo
	cd $(BUILD_WORK)/wptc-track/tracks && ./autogen.sh -C \
	$(DEFAULT_CONFIGURE_FLAGS) \
	--with-tracks-data=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wptc-track/data \
	--datadir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wptc-track
	+$(MAKE) -C $(BUILD_WORK)/wptc-track
	+$(MAKE) -C $(BUILD_WORK)/wptc-track install \
		DESTDIR=$(BUILD_STAGE)/wptc-track
	touch $(BUILD_WORK)/wptc-track/.build_complete
endif

wptc-track-package: wptc-track-stage
	# wptc-track.mk Package Structure
	rm -rf $(BUILD_DIST)/wptc-track
	mkdir -p $(BUILD_DIST)/wptc-track
	
	# wptc-track.mk Prep wptc-track
	cp -a $(BUILD_STAGE)/wptc-track $(BUILD_DIST)
	
	# wptc-track.mk Sign
	$(call SIGN,wptc-track,general.xml)
	
	# wptc-track.mk Make .debs
	$(call PACK,wptc-track,DEB_WPTC_TRACK_V)
	
	# wptc-track.mk Build cleanup
	rm -rf $(BUILD_DIST)/wptc-track

.PHONY: wptc-track wptc-track-package
