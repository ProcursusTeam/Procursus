ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


setup_CF600:
	@echo "Running setup_CF600"
	@mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)$(MEMO_PREFIX)/{{,System}/Library/Frameworks,$(MEMO_SUB_PREFIX)/{include/{bsm,objc,os/internal,sys,CoreFoundation,Foundation,IOKit/kext,libkern,kern,arm,{mach/,}machine,CommonCrypto,Security,CoreSymbolication,Kernel/{kern,IOKit,libkern},rpc,rpcsvc,ktrace,mach-o,dispatch},lib/pkgconfig,$(MEMO_ALT_PREFIX)/lib}} \
		$(BUILD_SOURCE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_STRAP)

	@rm -rf $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/System
	@$(LN_SR) $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include{,/System}

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include, \
		https://github.com/apple-oss-distributions/launchd/raw/launchd-842.92.1/liblaunch/{bootstrap$(comma)vproc}_priv.h \
		https://github.com/apple-oss-distributions/libplatform/raw/libplatform-273.100.5/private/_simple.h \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/{EXTERNAL_HEADERS/mach-o/nlist$(comma)osfmk/mach/vm_statistics}.h \
		https://github.com/apple-oss-distributions/libmalloc/raw/libmalloc-374.100.5/private/stack_logging.h \
		https://github.com/apple-oss-distributions/Libc/raw/Libc-1534.40.2/{gen/get_compat$(comma)include/struct}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include, \
		https://github.com/apple-oss-distributions/libutil/raw/libutil-60/{mntopts$(comma)libutil}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach-o, \
		https://github.com/apple-oss-distributions/dyld/raw/dyld-955/{include/mach-o/dyld_{process_info$(comma)introspection}$(comma)cache-builder/dyld_cache_format}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Kernel/kern, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/osfmk/kern/ledger.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Kernel/IOKit, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/iokit/IOKit/IOKitDebug.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Kernel/libkern, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/libkern/libkern/OSKextLibPrivate.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/kern,https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/osfmk/kern/debug.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/arm, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-4570/{bsd/arm/disklabel$(comma)osfmk/arm/cpu_capabilities}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os, \
		https://github.com/apple-oss-distributions/Libc/raw/Libc-1506.40.4/os/assumes.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CommonCrypto, \
		https://github.com/apple-oss-distributions/CommonCrypto/raw/CommonCrypto-60198.40.3/include/Private/CommonDigestSPI.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/bsm, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/bsd/bsm/audit_kevents.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/kext, \
		https://github.com/apple-oss-distributions/IOKitUser/raw/IOKitUser-1955.100.5/kext.subproj/{KextManagerPriv$(comma)OSKext$(comma)OSKextPrivate$(comma)kextmanager_types$(comma){fat$(comma)macho$(comma)misc}_util}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security, \
		https://github.com/apple-oss-distributions/Security/raw/Security-60420.40.34.0.1/OSX/libsecurity_keychain/lib/SecKeychainPriv.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-60420.40.34.0.1/OSX/libsecurity_codesigning/lib/Sec{CodeSigner$(comma){Code$(comma)Requirement}Priv}.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-60420.40.34.0.1/base/SecBasePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation, \
		https://github.com/apple-oss-distributions/CF/raw/CF-1153.18/CFBundlePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504//libkern/libkern/{OSKextLibPrivate$(comma)mkext$(comma)prelink}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/internal, \
		https://github.com/apple-oss-distributions/libplatform/raw/libplatform-126.50.8/include/os/internal/{internal_shared$(comma)atomic$(comma)crashlog}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/bsd/sys/{fcntl$(comma)fsctl$(comma)spawn_internal$(comma)resource$(comma)event$(comma)kdebug$(comma)proc$(comma)proc_info$(comma)acct$(comma)event$(comma)mbuf$(comma)kern_memorystatus}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/uuid, \
		https://github.com/apple-oss-distributions/Libc/raw/Libc-1534.40.2/uuid/namespace.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/iokit/IOKit/IOKitDebug.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/kext, \
		https://github.com/apple-oss-distributions/IOKitUser/raw/IOKitUser-1845.81.1/kext.subproj/{KextManagerPriv$(comma)OSKext$(comma)OSKextPrivate$(comma)kextmanager_types$(comma){fat$(comma)macho$(comma)misc}_util}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security, \
		https://github.com/apple-oss-distributions/Security/raw/Security-60420.40.34.0.1/OSX/libsecurity_keychain/lib/SecKeychainPriv.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-60420.40.34.0.1/OSX/libsecurity_codesigning/lib/Sec{CodeSigner$(comma){Code$(comma)Requirement}Priv}.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-60420.40.34.0.1/base/SecBasePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation, \
		https://github.com/apple-oss-distributions/CF/raw/CF-1153.18/CFBundlePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/osfmk/machine/cpu_capabilities.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/libkern/libkern/{OSKextLibPrivate$(comma)mkext$(comma)prelink}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/internal, \
		https://github.com/apple-oss-distributions/libplatform/raw/libplatform-126.50.8/include/os/internal/{internal_shared$(comma)atomic$(comma)crashlog}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/bsd/sys/{fcntl$(comma)fsctl$(comma)spawn_internal$(comma)resource$(comma)event$(comma)kdebug$(comma)proc$(comma)proc_info$(comma)acct$(comma)event$(comma)mbuf$(comma)kern_memorystatus}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ktrace, \
		https://github.com/Torrekie/apple_internal_sdk/raw/fa5457b4e5246d20da5a74f1449b37dfd79f1248/usr/include/ktrace/{private$(comma)session}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/perfdata, \
		https://github.com/Torrekie/apple_internal_sdk/raw/757ad82d5a680005bd253447dd3842217c6c8abc/usr/include/perfdata/perfdata.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreSymbolication, \
		https://github.com/Torrekie/apple_internal_sdk/raw/fa5457b4e5246d20da5a74f1449b37dfd79f1248/System/Library/PrivateFrameworks/CoreSymbolication.framework/Headers/CoreSymbolication{$(comma)Private}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/dispatch, \
		https://github.com/apple-oss-distributions/libdispatch/raw/libdispatch-1412/private/{private$(comma)benchmark$(comma){apply$(comma)channel$(comma)data$(comma)introspection$(comma)io$(comma)layout$(comma)mach$(comma)queue$(comma)source$(comma)time$(comma)workloop}_private}.h)

	@cp -a $(BUILD_MISC)/{libxml-2.0,zlib}.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

ifeq ($(UNAME),FreeBSD)
	@# FreeBSD's LLVM does not have stdbool.h, stdatomic.h, and stdarg.h
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Headers/{stdbool,stdatomic,stdarg}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af /usr/include/stdalign.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys, \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/bsd/sys/resource.h \
		https://github.com/apple-oss-distributions/xnu/raw/rel/xnu-1504/bsd/sys/vnioctl.h)

	@# Copy headers from MacOSX.sdk
	@cp -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,hfs,net,netinet,servers,timeconv.h,launch.h,libproc.h,crt_externs.h,secure} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/objc
	@cp -af $(MACOSX_SYSROOT)/usr/include/libkern/{OSDebug.h,OSKextLib.h,OSReturn.h,OSTypes.h,machine} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern
	@cp -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,ptrace,kern*,random,reboot,user,vnode,disk,vmmeter,conf}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/sys/disklabel.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys/
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/machine/{byte_order,disklabel,endian,_limits,limits,locks,machine_routines,_param,param,signal,spl,_structs,_types,types,vmparam}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine/
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Security.framework/Headers/{mds_schema,oidsalg,SecKeychainSearch,certextensions,Authorization,eisl,SecKeychainItem,oidscrl,cssmcspi,CSCommon,cssmaci,SecCode,CMSDecoder,oidscert,SecRequirement,AuthSession,cssmconfig,cssmkrapi,SecPolicySearch,SecAccess,cssmtpi,SecACL,cssmapi,cssmcli,mds,x509defs,oidsbase,cssmspi,cssmkrspi,cssmdli,SecAsn1Coder,cssm,SecTrustedApplication,SecCodeHost,oidsattr,SecIdentitySearch,cssmtype,SecAsn1Types,emmtype,SecTrustSettings,SecStaticCode,emmspi,SecKeychain,CodeSigning,AuthorizationPlugin,cssmerr,AuthorizationTags,CMSEncoder,SecureDownload,SecAsn1Templates,AuthorizationDB,cssmapple}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security
	@cp -af $(MACOSX_SYSROOT)/usr/include/{ar,launch,libc,libcharset,localcharset,nlist,NSSystemDirectories,tzfile,vproc}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(MACOSX_SYSROOT)/usr/include/rpc/pmap_clnt.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/rpc
	@cp -af $(MACOSX_SYSROOT)/usr/include/rpcsvc/yp{_prot,clnt}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/rpcsvc
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/machine/thread_state.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/arm $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(BUILD_INFO)/availability.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os
ifneq ($(wildcard $(BUILD_MISC)/IOKit.framework.$(PLATFORM)),)
	@cp -af $(BUILD_MISC)/IOKit.framework.$(PLATFORM) $(BUILD_BASE)/$(MEMO_PREFIX)/System/Library/Frameworks/IOKit.framework
endif

	@mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{CoreAudio,CoreFoundation}
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/CoreAudio.framework/Headers/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreAudio

	@# Patch headers from $(BARE_PLATFORM).sdk
	@if [ -f $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h ]; then sed -E 's/API_UNAVAILABLE(ios, watchos, tvos)//g' < $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation/CFUserNotification.h; fi
	@if [ -f $(TARGET_SYSROOT)/System/Library/Frameworks/Foundation.framework/Headers/NSObjCRuntime.h ]; then sed 's/__attribute__ ((format_arg(A)))//g' < $(TARGET_SYSROOT)/System/Library/Frameworks/Foundation.framework/Headers/NSObjCRuntime.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Foundation/NSObjCRuntime.h; fi
	@if [ -f $(TARGET_SYSROOT)/System/Library/Frameworks/Foundation.framework/Headers/NSURLSession.h ]; then sed 's/_Nullable_result//g' < $(TARGET_SYSROOT)/System/Library/Frameworks/Foundation.framework/Headers/NSURLSession.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Foundation/NSURLSession.h; fi
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/time.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/task.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/mach_host.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ucontext.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/signal.h
	@sed -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pthread.h
	@sed -i -E s/'__API_UNAVAILABLE\(.*\)'// $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/IOKitLib.h
	@sed -E -e '\|/var/tmp|! s|"/var|"$(MEMO_PREFIX)/var|g' -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/pwd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pwd.h
	@sed -E -e '\|/var/tmp|! s|"/var|"$(MEMO_PREFIX)/var|g' -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/grp.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/grp.h
	@sed -E -e 's|"/var|"$(MEMO_PREFIX)/var|g' -e 's|"/tmp|"$(MEMO_PREFIX)/tmp|g' -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/paths.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/paths.h

	@#Patch downloaded headers
	@sed -i '1s|^|#include <Security/cssmapi.h>\n#include <Security/SecKeychain.h>\n|' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security/SecKeychainPriv.h
	@sed -i 's/, ios(NA), bridgeos(NA)//' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security/SecBasePriv.h
	@sed -i 's/__API_UNAVAILABLE(ios, tvos, watchos) __API_UNAVAILABLE(bridgeos)//' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach-o/dyld_process_info.h
	@sed -i 's/, bridgeos(4.0)//' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/dispatch/{mach,data,source}_private.h
	@echo -e '#ifndef MNT_CPROTECT\n#define MNT_CPROTECT 0x00000080\n#endif' >> $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mntopts.h
	@sed -i 's/fsctl(const char /bad_redecleration_of_fsctl(const char/g' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/System/sys/fsctl.h

	@# Setup libiosexec
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.1.tbd
	@$(LN_S) libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.tbd
	@rm -f $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.*.dylib
ifneq ($(MEMO_NO_IOSEXEC),1)
	@sed -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{unistd,pwd,grp}.h
endif
endif

ifneq ($(MEMO_QUIET),1)
	@echo Makeflags: $(MAKEFLAGS)
	@echo Path: $(PATH)
endif # ($(MEMO_QUIET),1)