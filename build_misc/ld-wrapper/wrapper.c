#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/wait.h>

#ifndef LINKER
#define LINKER "/usr/libexec/ld"
#endif

#ifndef LDID
#define LDID "/usr/bin/ldid"
#endif

#ifndef ENTS
#define ENTS "/usr/share/entitlements/general.xml"
#endif

extern char** environ;

int main (int argc, char *argv[]) {
	int i=0;
	char *out;
	
	for (i=1; i< argc; i++) {
		if (!strcmp(argv[i],"-o"))
			out=argv[i + 1];
	}
	if (access(out, F_OK) != -1 && remove(out) == -1) {
		printf("Could not remove existing file: %s", out);
		return 1;
	}

	pid_t pid;
	int status;
	status = posix_spawn(&pid, LINKER, NULL, NULL, argv, environ);
	if (status == 0) {
 		if (waitpid(pid, &status, 0) == -1) {
			perror("waitpid");
		}
	} else {
		printf("posix_spawn: Could not execute %s, %s\n", LINKER, strerror(status));
		return 1;
	}

	char* entitlements = getenv("ENTITLEMENTS");
	if (entitlements != NULL && access(entitlements, R_OK) == -1) {
		printf("Cannot read entitlements at path: %s\n", entitlements);
		entitlements = ENTS;
	} else if (entitlements == NULL) {
		entitlements = ENTS;
	}

	if (access(out, R_OK|W_OK) != -1) {
		char S[strlen(entitlements)+3];
		S[0] = '-';
		S[1] = 'S';
		strcpy(S+2, entitlements);
		char *args[] = {LDID, S, out, NULL};
		status = posix_spawn(&pid, LDID, NULL, NULL, args, environ);
		if (status == 0) {
 			if (waitpid(pid, &status, 0) == -1) {
				perror("waitpid");
			}
		} else {
			printf("posix_spawn: Could not execute %s, %s\n", LDID, strerror(status));
		}
	}
	return 0;
}
