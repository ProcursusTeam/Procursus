ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

BASE_VERSION := 1-5
DEB_BASE_V   ?= $(BASE_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/base/.build_complete),)
base:
	@echo "Using previously built base."
else
base:
	mkdir -p $(BUILD_STAGE)/base/{Applications,bin,boot,dev,etc/{default,profile.d},lib,Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},mnt,sbin,System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},tmp,usr/{bin,games,include,sbin,share/{dict,misc}},var/{backups,cache,db,empty,lib/{dpkg,misc},local,lock,log,logs,mobile/{Library/Preferences,Media},msgs,preferences,root/Media,run,spool,tmp,vm}}
	touch $(BUILD_STAGE)/base/.build_complete
endif

base-package: base-stage
	# base.mk Package Structure
	rm -rf $(BUILD_DIST)/base
	mkdir -p $(BUILD_DIST)/base
	
	# base.mk Prep base
	$(FAKEROOT) cp -a $(BUILD_STAGE)/base/* $(BUILD_DIST)/base
	
	# base.mk Make .debs
	$(call PACK,base,DEB_BASE_V)
	
	# base.mk Build cleanup
	rm -rf $(BUILD_DIST)/base

.PHONY: base base-package
