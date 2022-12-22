#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef TOOL
#	define TOOL "/usr/bin/cc"
#endif

#ifndef DEFAULT_SYSROOT
#	define DEFAULT_SYSROOT "/usr/share/SDKs/iPhoneOS.sdk"
#endif

void
append_env(char *name, char *value)
{
	char *out = NULL;
	char *cur = NULL;
	if ((cur = getenv(name)) == NULL)
		cur = "";
	asprintf(&out, "%s%s%s", cur, *cur == '\0' ? "" : ":", value);
	setenv(name, out, 1);
	free(out);
}

bool
strstartswith(char *s1, char *s2)
{
	if (strlen(s1) < strlen(s2))
		return false;
	else
		return memcmp(s1, s2, strlen(s2)) == 0;
}

int
main(int argc, char **argv)
{
	char *skip[6] = {"-isysroot", "-syslibroot", "-Wl,-syslibroot", "--sysroot", "-nostdsysteminc", "-nostdinc"};
	if (getenv("SDKROOT") == NULL) {
		for (int i = 1; i < argc; i++)
			for (int j = 0; j < 6; j++)
				if (strstartswith(argv[i], skip[j]))
					goto exec;
		setenv("SDKROOT", DEFAULT_SYSROOT, 1);
		append_env("CPATH", "/usr/include:/usr/local/include");
#ifdef EXTRA_CPATH
		append_env("CPATH", EXTRA_CPATH);
#endif
		append_env("LIBRARY_PATH", "/usr/lib:/usr/local/lib");
#ifdef EXTRA_LIBRARY_PATH
		append_env("LIBRARY_PATH", EXTRA_LIBRARY_PATH);
#endif
	}
exec:
	execv(TOOL, argv);
	fprintf(stderr, "Can't exec \"%s\": %s\n", TOOL, strerror(errno));
	return 1;
}
