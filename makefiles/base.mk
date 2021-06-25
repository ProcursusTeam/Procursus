ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS += base
BASE_VERSION  := 1-5
DEB_BASE_V    ?= $(BASE_VERSION)

base:
	mkdir -p $(BUILD_STAGE)/base/{Applications,bin,boot,dev,etc/{default,profile.d},lib,Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},mnt,sbin,System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},tmp,usr/{bin,games,include,sbin,share/{dict,misc}},var/{backups,cache,db,empty,lib/misc,local,lock,log,logs,mobile/{Library/Preferences,Media},msgs,preferences,root/Media,run,spool,tmp,vm}}
	touch $(BUILD_STAGE)/base/var/run/utmp

base-package: base-stage
	# base.mk Package Structure
	rm -rf $(BUILD_DIST)/base
	mkdir -p $(BUILD_DIST)/base

	# base.mk Prep base
	cp -a $(BUILD_STAGE)/base/* $(BUILD_DIST)/base

	# base.mk Permissions
	$(FAKEROOT) chown 0:80 $(BUILD_DIST)/base/{,Applications,Library/{,Frameworks,Preferences,Ringtones,Wallpaper},etc,tmp,var/{,db}}
	$(FAKEROOT) chown 0:3 $(BUILD_DIST)/base/var/empty
	$(FAKEROOT) chown 0:20 $(BUILD_DIST)/base/var/local
	$(FAKEROOT) chown 0:1 $(BUILD_DIST)/base/var/run
	$(FAKEROOT) chown -R 501:501 $(BUILD_DIST)/base/var/mobile
	$(FAKEROOT) chmod 0775 $(BUILD_DIST)/base/{Applications,Library,var/run}
	$(FAKEROOT) chmod 2775 $(BUILD_DIST)/base/var/local
	$(FAKEROOT) chmod 1775 $(BUILD_DIST)/base/var/{lock,tmp}
	$(FAKEROOT) chmod 0775 $(BUILD_DIST)/base/var/root
	$(FAKEROOT) chmod 0644 $(BUILD_DIST)/base/var/run/utmp

	# base.mk Make .debs
	$(call PACK,base,DEB_BASE_V,2)

	# base.mk Build cleanup
	rm -rf $(BUILD_DIST)/base

.PHONY: base base-package

endif # ($(MEMO_TARGET),darwin-\*)
