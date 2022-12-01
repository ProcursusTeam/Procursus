ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS  += dyld
DYLD_VERSION := 1042.1
DEB_DYLD_V   ?= $(DYLD_VERSION)

DYLD_CXXFLAGS := -std=c++20 -Icommon -DPRIVATE=1 -D__APPLE_API_PRIVATE=1 -Werror=nonportable-include-path -I. -Iinclude/mach-o -Ilibdyld -Idyld -Ilsl -Iinclude -Icache-builder -Icache_builder -Ilibdyld_introspection -DTARGET_OS_BRIDGE=0 -DSUPPORT_ARCH_arm64e=1 -DSUPPORT_ARCH_arm64_32=1 -Wno-assume
DYLD_EXE	  := dyld_closure_util dyld_shared_cache_util dyld_info dyld_usage dyld_inspect

dyld-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,dyld,$(DYLD_VERSION),dyld-$(DYLD_VERSION))
	$(call EXTRACT_TAR,dyld-$(DYLD_VERSION).tar.gz,dyld-dyld-$(DYLD_VERSION),dyld)
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/dyld, https://github.com/apple-oss-distributions/AvailabilityVersions/raw/AvailabilityVersions-111.0.1/{availability.pl$(comma)build_version_map.rb$(comma)print_dyld_os_versions.rb} https://github.com/Torrekie/apple_internal_sdk/raw/dd8ca4ba4c0556a1dbf5a49eaa683795996f49c2/misc/CrashReporterClient/CrashReporterClient.c)
	chmod 755 $(BUILD_WORK)/dyld/availability.pl
	sed -i \
		-e 's/__API_UNAVAILABLE\(.*\)/;/g' \
		-e 's/\, bridgeos(.*))/)/g' \
		$(BUILD_WORK)/dyld/{include,common,include/mach-o}/*.h
	sed -i '/#include <rootless.h>/d' $(BUILD_WORK)/dyld/cache-builder/FileUtils.cpp
	sed -i 's|struct dyld_all_image_infos;$$|struct dyld_all_image_infos; extern "C" uint64_t kdebug_trace_string(uint32_t debugid, uint64_t str_id, const char *str);|' $(BUILD_WORK)/dyld/dyld/Tracing.h
	sed -i 's|using dyld3::MachOAnalyzer;$$|using dyld3::MachOAnalyzer; extern "C" bool kdebug_is_enabled(uint32_t debugid);|' $(BUILD_WORK)/dyld/dyld/DyldRuntimeState.cpp
	sed -i 's|// #include <System/os/reason_private.h>|extern "C" { bool kdebug_is_enabled(uint32_t debugid); int kdebug_trace(uint32_t debugid, uint64_t arg1, uint64_t arg2, uint64_t arg3, uint64_t arg4); };|' $(BUILD_WORK)/dyld/dyld/Tracing.cpp
	sed -i 's|#include <System/sys/mman.h>|#include <sys/mman.h>|g' $(BUILD_WORK)/dyld/dyld/DyldDelegates.cpp
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1800 ] && echo 1),1)
	sed -i 's/task_read_for_pid/task_for_pid/g' $(BUILD_WORK)/dyld/other-tools/dyld_inspect.cpp
endif
	mkdir -p $(BUILD_STAGE)/dyld/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

dyld-prepare-build: dyld-setup
	ruby $(BUILD_WORK)/dyld/build_version_map.rb $(BUILD_WORK)/dyld/availability.pl > $(BUILD_WORK)/dyld/dyld/VersionMap.h
	ruby $(BUILD_WORK)/dyld/print_dyld_os_versions.rb $(BUILD_WORK)/dyld/availability.pl > $(BUILD_WORK)/dyld/dyld/for_dyld_priv.inc.h
	cd $(BUILD_WORK)/dyld; \
		echo -e "#include \"PrebuiltLoader.h\"\nint foo() { return sizeof(dyld4::PrebuiltLoader)+sizeof(dyld4::PrebuiltLoaderSet)+sizeof(dyld4::ObjCBinaryInfo)+sizeof(dyld4::Loader::DylibPatch); }\n" > test.cpp; \
		$(CXX) $(CXXFLAGS) $(DYLD_CXXFLAGS) -Wno-incompatible-sysroot -fsyntax-only -Xclang -fdump-record-layouts -Icommon -Idyld -Iinclude -Icache-builder test.cpp > test.out; \
		grep -A100 "class dyld4::PrebuiltLoader"        test.out | grep -B100 -m1 sizeof= > pbl.ast; \
		grep -A100 "struct dyld4::PrebuiltLoaderSet"    test.out | grep -B100 -m1 sizeof= > pbls.ast; \
		grep -A100 "struct dyld4::ObjCBinaryInfo"       test.out | grep -B100 -m1 sizeof= > pblsobjc.ast; \
		grep -A100 "struct dyld4::Loader::DylibPatch"   test.out | grep -B100 -m1 sizeof= > dylibpatch.ast; \
		cat pbl.ast pbls.ast pblsobjc.ast dylibpatch.ast | md5 | awk '{print "#define PREBUILTLOADER_VERSION 0x" substr($$0,0,8)}' > dyld/PrebuiltLoader_version.h; \
	$(CC) $(CFLAGS) -c CrashReporterClient.c;

$(BUILD_WORK)/dyld/dyld_closure_util: dyld-prepare-build
	cd $(BUILD_WORK)/dyld; \
		$(CXX) $(DYLD_CXXFLAGS) $(CXXFLAGS) $(LDFLAGS) other-tools/dyld_closure_util.cpp common/*.cpp lsl/*.cpp -DBUILDING_CLOSURE_UTIL=1 dyld/{DebuggerSupport,Tracing,SharedCacheRuntime,DyldProcessConfig,DyldDelegates,PrebuiltObjC,JustInTimeLoader,Loader,DyldRuntimeState,PrebuiltLoader,PrebuiltSwift}.cpp -o dyld_closure_util; 

$(BUILD_WORK)/dyld/dyld_shared_cache_util: dyld-prepare-build
	cd $(BUILD_WORK)/dyld; \
		$(CXX) $(DYLD_CXXFLAGS) $(CXXFLAGS) $(LDFLAGS) -DBUILDING_SHARED_CACHE_UTIL=1 CrashReporterClient.o common/*.cpp lsl/*.cpp libdyld_introspection/*.cpp other-tools/{dyld_shared_cache_util,dsc_extractor}.cpp dyld/{DyldProcessConfig,DyldDelegates,DyldRuntimeState}.cpp -o dyld_shared_cache_util;

$(BUILD_WORK)/dyld/dyld_info: dyld-prepare-build
	cd $(BUILD_WORK)/dyld; \
		$(CXX) $(DYLD_CXXFLAGS) $(CXXFLAGS) $(LDFLAGS) ./cache-builder/FileUtils.cpp lsl/*.cpp common/{CachePatching,ClosureFileSystemNull,ClosureFileSystemPhysical,Diagnostics,DyldSharedCache,FileManager,MachOAnalyzer,MachOFile,MachOLayout,MachOLoaded,MetadataVisitor,MurmurHash,OptimizerSwift,PerfectHash,ProcessAtlas,SwiftVisitor,Utils}.cpp other-tools/dyld_info.cpp -DBUILDING_DYLDINFO=1 -o dyld_info;

$(BUILD_WORK)/dyld/dyld_usage: dyld-prepare-build
	cd $(BUILD_WORK)/dyld; \
		$(CXX) $(DYLD_CXXFLAGS) $(CXXFLAGS) $(LDFLAGS) lsl/*.cpp common/{CachePatching,ClosureFileSystemNull,ClosureFileSystemPhysical,Diagnostics,DyldSharedCache,FileManager,MachOAnalyzer,MachOFile,MachOLayout,MachOLoaded,MetadataVisitor,MurmurHash,OptimizerSwift,PerfectHash,ProcessAtlas,SwiftVisitor,Utils}.cpp libdyld_introspection/*.cpp other-tools/dyld_usage.cpp -DBUILDING_DYLDUSAGE=1 -F$(BUILD_MISC)/PrivateFrameworks -framework ktrace -o dyld_usage

$(BUILD_WORK)/dyld/dyld_inspect: dyld-prepare-build
	cd $(BUILD_WORK)/dyld; \
		$(CXX) $(DYLD_CXXFLAGS) $(CXXFLAGS) $(LDFLAGS) lsl/*.cpp common/{CachePatching,ClosureFileSystemNull,ClosureFileSystemPhysical,Diagnostics,DyldSharedCache,FileManager,MachOAnalyzer,MachOFile,MachOLayout,MachOLoaded,MetadataVisitor,MurmurHash,OptimizerSwift,PerfectHash,ProcessAtlas,SwiftVisitor,Utils}.cpp libdyld_introspection/*.cpp other-tools/dyld_inspect.cpp -DBUILDING_DYLDINSPECT=1 -o dyld_inspect

ifneq ($(wildcard $(BUILD_WORK)/dyld/.build_complete),)
dyld:
	@echo "Using previously built dyld."
else
dyld: dyld-setup $(patsubst %, $(BUILD_WORK)/dyld/%, $(DYLD_EXE))
	$(INSTALL) -m755 $(patsubst %, $(BUILD_WORK)/dyld/%, $(DYLD_EXE)) $(BUILD_STAGE)/dyld/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(INSTALL) -m644 $(BUILD_WORK)/dyld/doc/man/man1/dyld_{info,usage}.1 $(BUILD_STAGE)/dyld/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(call AFTER_BUILD)
endif

dyld-package: dyld-stage
	# dyld.mk Package Structure
	rm -rf $(BUILD_DIST)/dyld-tools

	# dyld.mk Prep dyld-tools
	cp -a $(BUILD_STAGE)/dyld $(BUILD_DIST)/dyld-tools

	# dyld.mk Sign
	$(call SIGN,dyld-tools,dyld-tools.xml)

	# dyld.mk Make .debs
	$(call PACK,dyld-tools,DEB_DYLD_V)

	# dyld.mk Build cleanup
	rm -rf $(BUILD_DIST)/dyld-tools

.PHONY: dyld dyld-package
endif
