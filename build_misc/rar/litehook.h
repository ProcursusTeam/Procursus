// This file is part of Dopamine and is licensed under MIT
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#ifdef __arm64__
#include <stdio.h>
#include <stdbool.h>
#include <mach/mach.h>

kern_return_t litehook_hook_function(void *source, void *target);
#endif
#endif
