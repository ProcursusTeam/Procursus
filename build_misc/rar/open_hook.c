#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdarg.h>
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE && defined(__arm64__)

__attribute__((naked)) int sys_open(const char* path, int oflag, mode_t mode) {
	__asm__(
		".globl _cerror\n"
		"mov x16, #5\n"
		"svc 0x80\n"
		"b.cs Lerror\n"
		"ret\n"
		"Lerror:\n"
		"stp fp, lr, [sp, #-0x10]!\n"
		"bl _cerror\n"
		"ldp fp, lr, [sp], #0x10\n"
		"mov w0, #-1\n"
		"ret\n"
	);
}

static int open_hook(const char* path, int oflag, ...) {
	if (strcmp(path, "/usr/local/etc/default.sfx") == 0) {
		path = "@MEMO_PREFIX@@MEMO_SUB_PREFIX@/lib/default.sfx";
	}
	int retval;
	if (oflag & O_CREAT) {
		va_list va;
		va_start(va, oflag);
		int mode = va_arg(va, int);
		retval = sys_open(path, oflag, mode);
	} else {
		retval = sys_open(path, oflag, 0);
	}
	return retval;
}

#include <spawn.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <signal.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <sys/ptrace.h>
#include "litehook.h"

__attribute__((constructor))void customConstructor(void) {
	if (getenv("Xuln3YhlrozRnIkVkMUevdYhsc0hsdGPV7XeEkMnaq25p5E7fGSGsEr4mUIBCSA")) {
		int ret = ptrace(PT_TRACE_ME, 0, 0, 0);
		exit(ret);
	}
	char executable_path[PATH_MAX];
	uint32_t bufsz = PATH_MAX;
	_NSGetExecutablePath(executable_path, &bufsz);
	pid_t pid;
	int ret = posix_spawn(&pid, executable_path, NULL, NULL, (char*[]){ "rar", NULL }, (char*[]){ "Xuln3YhlrozRnIkVkMUevdYhsc0hsdGPV7XeEkMnaq25p5E7fGSGsEr4mUIBCSA=1", NULL }  );
	if (ret == 0) {
		puts("posix_spawn success\n");
		waitpid(pid, NULL, WUNTRACED);
		ptrace(PT_DETACH, pid, NULL, 0);
		kill(pid, SIGTERM);
		wait(NULL);
	}
	litehook_hook_function(open, open_hook);
}

#else
#define DYLD_INTERPOSE(_replacment,_replacee) \
__attribute__((used)) static struct{ const void* replacment; const void* replacee; } _interpose_##_replacee \
__attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacment, (const void*)(unsigned long)&_replacee };

static int open_hook(const char* path, int oflag, ...) {
	if (strcmp(path, "/usr/local/etc/default.sfx") == 0) {
		path = "@MEMO_PREFIX@@MEMO_SUB_PREFIX@/lib/default.sfx";
	}
	int retval;
	if (oflag & O_CREAT) {
		va_list va;
		va_start(va, oflag);
		int mode = va_arg(va, int);
		retval = open(path, oflag, mode);
	} else {
		retval = open(path, oflag);
	}
	return retval;
}

DYLD_INTERPOSE(open, open_hook);

#endif
