ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
SUBPROJECTS    += dtrace
DTRACE_VERSION := 375
XNU_VERSION    := 8019.41.5
DEB_DTRACE_V   ?= $(DTRACE_VERSION)

# FIXME: add -DDTRACE_USE_CORESYMBOLICATION=1 and fix errors
DTRACE_CFLAGS := $(shell echo -I$(BUILD_WORK)/dtrace/{include,lib/libproc,compat/opensolaris,compat/opensolaris/sys,lib/libelf,lib/libdwarf/cmplrs,lib/libdwarf,lib/libctf/common,lib/libdtrace/{apple,arm,i386,common}} -DPRIVATE)

dtrace-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,dtrace,$(DTRACE_VERSION),dtrace-$(DTRACE_VERSION))
	$(call GITHUB_ARCHIVE,apple-oss-distributions,xnu,$(XNU_VERSION),xnu-$(XNU_VERSION))
	$(call EXTRACT_TAR,dtrace-$(DTRACE_VERSION).tar.gz,dtrace-dtrace-$(DTRACE_VERSION),dtrace)
	$(call EXTRACT_TAR,xnu-$(XNU_VERSION).tar.gz,xnu-xnu-$(XNU_VERSION),dtrace/xnu)
	$(call DO_PATCH,dtrace,dtrace,-p1)
	wget -q -nc -P$(BUILD_WORK)/dtrace/lib/libproc \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-8019.41.5/libsyscall/wrappers/libproc/libproc_{private,internal}.h
	sed -i '1s/^/#include <rtld_db.h>\n/' $(BUILD_WORK)/dtrace/lib/libdtrace/common/dt_proc.h
	sed -i '1s|^|#include <sys/utsname.h>\n|' $(BUILD_WORK)/dtrace/lib/libdtrace/common/dt_impl.h
	sed -i '1s|^|#include "$(BUILD_WORK)/dtrace/lib/libproc/libproc.h"\n|' $(BUILD_WORK)/dtrace/{lib/libdtrace/{common/dt_aggregate.c,apple/dt_{proc,pid}_apple.c},cmd/{dtrace/dtrace.c,plockstat/plockstat.c}}
	sed -i '1s|^|#include <dispatch/dispatch.h>\n|' $(BUILD_WORK)/dtrace/lib/libdtrace/common/dt_open.c
	sed -i '1s|^|#include <string.h>\n#include <mach-o/loader.h>\n|' $(BUILD_WORK)/dtrace/lib/libdtrace/apple/dt_module_apple.c
	sed -i '1s|^|#include <pthread/qos_private.h>\n|' $(BUILD_WORK)/dtrace/cmd/dtrace/dtrace.c
	rm -f $(BUILD_WORK)/dtrace/tools/ctfconvert/compare.c
	mkdir -p $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{{s,}bin,lib/dtrace/{arm{,64},x86_64},share/man/man1}

ifneq ($(wildcard $(BUILD_WORK)/dtrace/.build_complete),)
dtrace:
	@echo "Using previously built dtrace."
else
# libdtrace does not have a soname
dtrace: dtrace-setup
	for d in lib{proc,ctf/common,dwarf,elf}; do \
		echo $${d}; \
		cd $(BUILD_WORK)/dtrace/lib/$${d}; \
			$(CC) $(DTRACE_CFLAGS) $(CFLAGS) -c *.c; \
			$(AR) cru joemama.a *.o; \
	done
	echo lib/libdtrace; cd $(BUILD_WORK)/dtrace/lib/libdtrace/common; \
		bison -dy dt_grammar.y && flex dt_lex.l && sed -i 's/char yytext\[\];/char \*yytext;/g' dt_impl.h;
	cd $(BUILD_WORK)/dtrace; \
		$(CC) $(DTRACE_CFLAGS) $(CFLAGS) $(LDFLAGS) -DYYDEBUG -L. -lstdc++ lib/lib{proc,ctf/common,dwarf,elf}/joemama.a -shared -install_name $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libdtrace.dylib -o libdtrace.dylib compat/opensolaris/darwin_shim.c lib/libdtrace/{apple,arm,common,i386}/*.c lib/libdtrace/apple/dt_ld.cpp;
	cd $(BUILD_WORK)/dtrace/cmd; \
		for bin in dtrace lockstat plockstat usdtheadergen; do \
			[ "$${bin}" = "lockstat" ] && LDFLAGS="$(LDFLAGS) $(BUILD_MISC)/dtrace/CoreSymbolication.tbd" || LDFLAGS="$(LDFLAGS)"; \
			echo $${bin}; \
			$(CC) -L.. $(DTRACE_CFLAGS) $(CFLAGS) $${LDFLAGS} -framework IOKit -framework CoreFoundation -ldtrace $${bin}/*.c -o ../$${bin}; \
			$(INSTALL) -m644 $${bin}/$${bin}.1 $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 2> /dev/null || true; \
		done;
	cd $(BUILD_WORK)/dtrace; \
		$(INSTALL) -m755 libdtrace.dylib $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib; \
		$(INSTALL) -m755 dtrace $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin; \
		$(INSTALL) -m755 lockstat plockstat usdtheadergen $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
		$(INSTALL) -m755 $$(find '$(BUILD_WORK)/dtrace/DTTk' -perm 755 -not -iname 'Index' -not -iname 'License' -not -iname 'Readme' -not -iname 'install') $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
		$(INSTALL) -m644 DTTk/Man/man1m/*.1m $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
		$(INSTALL) -m644 $$(find $(BUILD_WORK)/dtrace/xnu/bsd/dev/dtrace/scripts -name '*.d' -not -name '*arm*' -not -name '*x86_64*') dtrace/scripts/{procfs.d,dt_cpp.h} $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/dtrace; \
		$(INSTALL) -m644 script/swift_arm.d xnu/bsd/dev/dtrace/scripts/regs_arm.d $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/dtrace/arm; \
		$(INSTALL) -m644 scripts/swift_arm64.d xnu/bsd/dev/dtrace/scripts/{regs,ptrauth}_arm64.d $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/dtrace/arm64; \
		$(INSTALL) -m644 scripts/swift_x86_64.d xnu/bsd/dev/dtrace/scripts/regs_x86_64.d $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/dtrace/x86_64;
	chmod 755 $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/dtrace/*/swift_*.d
	$(call AFTER_BUILD,copy)
endif

dtrace-package: dtrace-stage
	# dtrace.mk Package Structure
	rm -rf $(BUILD_DIST)/{lib,}dtrace
	mkdir -p $(BUILD_DIST)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libdtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# dtrace.mk Prep dtrace
	cp -a $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share,{s,}bin} $(BUILD_DIST)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# dtrace.mk Prep libdtrace
	cp -a $(BUILD_STAGE)/dtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/libdtrace/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# dtrace.mk Sign
	$(call SIGN,dtrace,dtrace.xml)
	$(call SIGN,libdtrace,dtrace.xml)

	# dtrace.mk Make .debs
	$(call PACK,dtrace,DEB_DTRACE_V)
	$(call PACK,libdtrace,DEB_DTRACE_V)

	# dtrace.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lib,}dtrace

.PHONY: dtrace dtrace-package
endif
