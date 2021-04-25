#define _GNU_SOURCE

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stddef.h>
#include <unistd.h>
#include <limits.h>

char *get_executable_path(char *epath, size_t buflen) {
    char *p;
    ssize_t l = readlink("/proc/self/exe", epath, buflen - 1);
    if (l > 0) epath[l] = '\0';
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

    char *compiler;
    char *target;

    target_info(argv, &target, &compiler);
    if (!get_executable_path(execpath, sizeof(execpath))) abort();

    i = 0;

    args[i++] = compiler;

    args[i++] = "-target";
    args[i++] = target;

    args[i++] = "-mlinker-version=609";

    for (j = 1; j < argc; ++i, ++j)
        args[i] = argv[j];

    args[i] = NULL;

    setenv("COMPILER_PATH", execpath, 1);
    execvp(compiler, args);

    fprintf(stderr, "cannot invoke compiler!\n");
    return 1;
}
