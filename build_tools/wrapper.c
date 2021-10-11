#define _GNU_SOURCE

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stddef.h>
#include <unistd.h>
#include <limits.h>

#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__DragonFly__)
#include <sys/sysctl.h>
#endif

#ifdef __OpenBSD__
#include <sys/types.h>
#include <sys/user.h>
#include <sys/stat.h>
#endif

char *get_executable_path(char *epath, size_t buflen) {
    char *p;
#if defined(__FreeBSD__) || defined(__DragonFly__)
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };
    size_t l = buflen;
    if (sysctl(mib, 4, epath, &l, NULL, 0) != 0) return NULL;
#elif defined(__OpenBSD__)
    int mib[4];
    char **argv;
    size_t len;
    size_t l;
    const char *comm;
    int ok = 0;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC_ARGS;
    mib[2] = getpid();
    mib[3] = KERN_PROC_ARGV;
    if (sysctl(mib, 4, NULL, &len, NULL, 0) < 0)
        abort();
    if (!(argv = malloc(len)))
        abort();
    if (sysctl(mib, 4, argv, &len, NULL, 0) < 0)
        abort();
    comm = argv[0];
    if (*comm == '/' || *comm == '.') {
        char *rpath;
        if ((rpath = realpath(comm, NULL))) {
            strlcpy(epath, rpath, buflen);
            free(rpath);
            ok = 1;
        }
    }
    else {
        char *sp;
        char *xpath = strdup(getenv("PATH"));
        char *path = strtok_r(xpath, ":", &sp);
        struct stat st;
        if (!xpath)
            abort();
        while (path) {
            snprintf(epath, buflen, "%s/%s", path, comm);
            if (!stat(epath, &st) && (st.st_mode & S_IXUSR)) {
                ok = 1;
                break;
            }
            path = strtok_r(NULL, ":", &sp);
        }
        free(xpath);
    }
    free(argv);
    if (!ok) return NULL;
    l = strlen(epath);
#else
    ssize_t l = readlink("/proc/self/exe", epath, buflen - 1);
    if (l > 0) epath[l] = '\0';
#endif
    if (l <= 0) return NULL;
    epath[buflen - 1] = '\0';
    p = strrchr(epath, '/');
    if (p) *p = '\0';
    return epath;
}

char *get_filename(char *str) {
    char *p = strrchr(str, '/');
    return p ? &p[1] : str;
}

void target_info(char *argv[], char **triple, char **compiler) {
    char *p = get_filename(argv[0]);
    char *x = strrchr(p, '-');
    if (!x) abort();
    *compiler = &x[1];
    *x = '\0';
    *triple = p;
}

void env(char **p, const char *name, char *fallback) {
    char *ev = getenv(name);
    if (ev) { *p = ev; return; }
    *p = fallback;
}

int main(int argc, char *argv[]) {
    char **args = alloca(sizeof(char*) * (argc+12));
    int i, j;

    char execpath[PATH_MAX+1];
    char osvermin[64];

    char *compiler;
    char *target;

    char *sdk;
    char *cpu;

    target_info(argv, &target, &compiler);
    if (!get_executable_path(execpath, sizeof(execpath))) abort();

    env(&sdk, "TARGET_SYSROOT", NULL);
    env(&cpu, "MEMO_ARCH", NULL);
    env(&osvermin, "PLATFORM_VERSION_MIN", NULL);

    for (i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "-arch")) {
            cpu = NULL;
            break;
        }
    }

    i = 0;

    args[i++] = compiler;

    args[i++] = "-target";
    args[i++] = target;


    if (sdk) {
        args[i++] = "-isysroot";
        args[i++] = sdk;
    }

    if (cpu) {
        args[i++] = "-arch";
        args[i++] = cpu;
    }

    if (osvermin) args[i++] = osvermin;
    args[i++] = "-mlinker-version=609";

    for (j = 1; j < argc; ++i, ++j)
        args[i] = argv[j];

    args[i] = NULL;

    setenv("COMPILER_PATH", execpath, 1);
    execvp(compiler, args);

    fprintf(stderr, "cannot invoke compiler!\n");
    return 1;
}
