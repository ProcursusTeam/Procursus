ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += wptc-track
WPTC_TRACK_VERSION := 2020.09.26
DEB_WPTC_TRACK_V   ?= $(WPTC_TRACK_VERSION)

wptc-track-setup: setup
	$(call GITHUB_ARCHIVE,titoxd,wptc-track,$(WPTC_TRACK_VERSION),69bfe15eef70be9da64339eba41de1d00b0a6ec9)
	$(call EXTRACT_TAR,wptc-track-$(WPTC_TRACK_VERSION).tar.gz,wptc-track-69bfe15eef70be9da64339eba41de1d00b0a6ec9,wptc-track)
	$(SED) -i 's@../data@$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wptc-track@g' $(BUILD_WORK)/wptc-track/tracks/{refresh-nhc,track.c}
	$(SED) -i 's@../png/output.png@./track.png@g' $(BUILD_WORK)/wptc-track/tracks/track.c

ifneq ($(wildcard $(BUILD_WORK)/wptc-track/.build_complete),)
wptc-track:
	@echo "Using previously built wptc-track."
else
wptc-track: wptc-track-setup cairo
	cd $(BUILD_WORK)/wptc-track/tracks; \
	$(CC) $(CFLAGS) -g -Wall scales.c template.c tab.c track.c tcr.c atcf.c hurdat2.c hurdat.c md.c $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcairo.dylib -o track -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cairo
	mkdir -p $(BUILD_STAGE)/wptc-track/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share,bin,sbin}
	mkdir -p $(BUILD_STAGE)/wptc-track/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wptc-track
	$(GINSTALL) -Dm755 $(BUILD_WORK)/wptc-track/tracks/track $(BUILD_STAGE)/wptc-track/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/track
	$(GINSTALL) -Dm755 $(BUILD_WORK)/wptc-track/tracks/refresh-nhc $(BUILD_STAGE)/wptc-track/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	$(CP) -a $(BUILD_WORK)/wptc-track/data/* $(BUILD_STAGE)/wptc-track/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/wptc-track
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
