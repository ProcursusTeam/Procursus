#define LIBIOSEXEC_INTERNAL 1
#include <stdint.h>
#include <pwd.h>
#include <grp.h>

void testsudoers_setgrfile(const char *);
void testsudoers_setgrent(void);
void testsudoers_endgrent(void);
int testsudoers_setgroupent(int);
struct group *testsudoers_getgrent(void);
struct group *testsudoers_getgrnam(const char *);
struct group *testsudoers_getgrgid(gid_t);

void testsudoers_setpwfile(const char *);
void testsudoers_setpwent(void);
void testsudoers_endpwent(void);
int testsudoers_setpassent(int);
struct passwd *testsudoers_getpwent(void);
struct passwd *testsudoers_getpwnam(const char *);
struct passwd *testsudoers_getpwuid(uid_t);

char *testsudoers_getusershell(void);
void testsudoers_setusershell(void);
void testsudoers_endusershell(void);
void testsudoers_setshellfile(const char *file);

void testsudoers_ie_setgrfile(const char * a1) { testsudoers_setgrfile(a1); }
void testsudoers_ie_setgrent(void) { testsudoers_setgrent(); }
void testsudoers_ie_endgrent(void) { testsudoers_endgrent(); }
int testsudoers_ie_setgroupent(int a1) { return testsudoers_setgroupent(a1); }
struct group *testsudoers_ie_getgrent(void) { return testsudoers_getgrent(); }
struct group *testsudoers_ie_getgrnam(const char * a1) { return testsudoers_getgrnam(a1); }
struct group *testsudoers_ie_getgrgid(gid_t a1) { return testsudoers_getgrgid(a1); }

void testsudoers_ie_setpwfile(const char * a1) { testsudoers_setpwfile(a1); }
void testsudoers_ie_setpwent(void) { testsudoers_setpwent(); }
void testsudoers_ie_endpwent(void) { testsudoers_endpwent(); }
int testsudoers_ie_setpassent(int a1) { return testsudoers_ie_setpassent(a1); }
struct passwd *testsudoers_ie_getpwent(void) { return testsudoers_getpwent(); }
struct passwd *testsudoers_ie_getpwnam(const char * a1) { return testsudoers_getpwnam(a1); }
struct passwd *testsudoers_ie_getpwuid(uid_t a1) { return testsudoers_getpwuid(a1); }

char *testsudoers_ie_getusershell(void) { return testsudoers_getusershell(); }
void testsudoers_ie_setusershell(void) { testsudoers_setusershell(); }
void testsudoers_ie_endusershell(void) { testsudoers_endusershell(); }
void testsudoers_ie_setshellfile(const char *file) { testsudoers_setshellfile(file); }
