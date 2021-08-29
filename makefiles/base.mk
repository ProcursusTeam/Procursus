ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += base
BASE_VERSION  := 1-5
DEB_BASE_V    ?= $(BASE_VERSION)

base:
	mkdir -p \
		$(BUILD_STAGE)/base/$(MEMO_PREFIX)/{Applications,bin,boot,dev,lib,mnt,sbin,tmp, \
		etc/{default,profile.d}, \
		Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper}, \
		System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders}, \
		usr/{bin,games,include,sbin,share/{dict,misc}}, \
		var/{backups,cache,db,empty,lib/misc,local,lock,log,logs,msgs,preferences,run,spool,tmp,vm, \
		mobile/{Library/Preferences,Media}, \
		root/Media}}
	touch $(BUILD_STAGE)/base/$(MEMO_PREFIX)/var/run/utmp

base-package: base-stage
	# base.mk Package Structure
	rm -rf $(BUILD_DIST)/base

	# base.mk Prep base
	cp -a $(BUILD_STAGE)/base $(BUILD_DIST)

	# base.mk Make .debs
	$(call PACK,base,DEB_BASE_V,2)

	# base.mk Build cleanup
	rm -rf $(BUILD_DIST)/base

.PHONY: base base-package

endif # ($(MEMO_TARGET),darwin-\*)
