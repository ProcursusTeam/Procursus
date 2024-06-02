ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += base
BASE_VERSION  := 2
DEB_BASE_V    ?= $(BASE_VERSION)

APPLE_FILES_VERSION := 926.0.2

base-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,files,$(APPLE_FILES_VERSION),files-$(APPLE_FILES_VERSION))
	$(call EXTRACT_TAR,files-$(APPLE_FILES_VERSION).tar.gz,files-files-$(APPLE_FILES_VERSION),base)
	find $(BUILD_WORK)/base -name Makefile -delete

ifneq ($(wildcard $(BUILD_WORK)/base/.build_complete),)
base:
	@echo "Using previously built base."
else
base: base-setup
ifeq (,$(MEMO_PREFIX))
	mkdir -p \
		$(BUILD_STAGE)/base/$(MEMO_PREFIX)/{Applications,bin,boot,dev,lib,mnt,sbin,tmp,\
etc/{default,profile.d},\
Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},\
System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},\
$(MEMO_SUB_PREFIX)/{bin,games,include,sbin,share/{dict,misc}},\
var/{backups,cache,db,empty,lib/misc,local,lock,log,logs,msgs,preferences,run,spool,tmp,vm,\
mobile/{Library/Preferences,Media},\
root/Media}}
else
	mkdir -p \
		$(BUILD_STAGE)/base/$(MEMO_PREFIX)/{Applications,bin,boot,dev,lib,mnt,sbin,tmp,\
etc/{default,profile.d},\
Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},\
System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},\
$(MEMO_SUB_PREFIX)/{bin,games,include,sbin,share/{dict,misc}},\
var/{backups,cache,db,empty,lib/misc,local,lock,log,logs,mobile,msgs,preferences,run,root,spool,vm}}
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/passwd/passwd > $(BUILD_STAGE)/base/$(MEMO_PREFIX)/etc/passwd
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/passwd/master.passwd > $(BUILD_STAGE)/base/$(MEMO_PREFIX)/etc/master.passwd
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/passwd/group > $(BUILD_STAGE)/base/$(MEMO_PREFIX)/etc/group
endif
	install -m644 $(BUILD_WORK)/base/usr/share/dict/web2 $(BUILD_STAGE)/base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dict
	cp -a $(BUILD_WORK)/base/usr/share/man $(BUILD_STAGE)/base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	$(LN_S) web2 $(BUILD_STAGE)/base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dict/words
	$(LN_S) /var/db/timezone/localtime $(BUILD_STAGE)/base/$(MEMO_PREFIX)/etc/localtime
	touch $(BUILD_STAGE)/base/$(MEMO_PREFIX)/var/run/utmp
	$(call AFTER_BUILD)
endif

base-package: base-stage
	# base.mk Package Structure
	rm -rf $(BUILD_DIST)/base

	# base.mk Prep base
	cp -a $(BUILD_STAGE)/base $(BUILD_DIST)

	$(FAKEROOT) chmod 0644 $(BUILD_DIST)/base/$(MEMO_PREFIX)/var/run/utmp
	$(FAKEROOT) chown 0:1 $(BUILD_DIST)/base/$(MEMO_PREFIX)/var/run
	$(FAKEROOT) chown 0:3 $(BUILD_DIST)/base/$(MEMO_PREFIX)/var/empty
ifeq (,$(MEMO_PREFIX))
	$(FAKEROOT) chown 0:80 $(BUILD_DIST)/base/{,Applications,Library/{,Frameworks,Preferences,Ringtones,Wallpaper},etc,tmp,var/{,db}}
	$(FAKEROOT) chown 0:20 $(BUILD_DIST)/base/var/local
	$(FAKEROOT) chown -R 501:501 $(BUILD_DIST)/base/var/mobile
	$(FAKEROOT) chmod 0775 $(BUILD_DIST)/base/{Applications,Library,var/run}
	$(FAKEROOT) chmod 2775 $(BUILD_DIST)/base/var/local
	$(FAKEROOT) chmod 1775 $(BUILD_DIST)/base/var/{lock,tmp}
	$(FAKEROOT) chmod 0775 $(BUILD_DIST)/base/var/root
else
	$(FAKEROOT) chown -R 0:0 $(BUILD_DIST)/base
	$(FAKEROOT) chown -R 501:501 $(BUILD_DIST)/base/$(MEMO_PREFIX)/var/mobile
	$(FAKEROOT) chmod 0644 $(BUILD_STAGE)/base/$(MEMO_PREFIX)/etc/{passwd,group}
	$(FAKEROOT) chmod 0600 $(BUILD_STAGE)/base/$(MEMO_PREFIX)/etc/master.passwd
	$(FAKEROOT) chmod 1775 $(BUILD_DIST)/base/$(MEMO_PREFIX)/tmp
endif

	# base.mk Make .debs
	$(call PACK,base,DEB_BASE_V,2)

	# base.mk Build cleanup
	rm -rf $(BUILD_DIST)/base

.PHONY: base base-package

endif # ($(MEMO_TARGET),darwin-\*)
