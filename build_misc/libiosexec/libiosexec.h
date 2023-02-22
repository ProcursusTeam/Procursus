#ifndef LIBIOSEXEC_H
#define LIBIOSEXEC_H

#define IOSEXEC_PUBLIC __attribute__ ((visibility ("default")))
#define IOSEXEC_HIDDEN __attribute__ ((visibility ("hidden")))

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

IOSEXEC_PUBLIC int ie_execl(const char* path, const char* arg0, ...);
IOSEXEC_PUBLIC int ie_execle(const char* path, const char* arg0, ...);
IOSEXEC_PUBLIC int ie_execlp(const char* file, const char* arg0, ...);

IOSEXEC_PUBLIC int ie_execv(const char* path, char *const argv[]);
IOSEXEC_PUBLIC int ie_execvp(const char* file, char* const argv[]);
IOSEXEC_PUBLIC int ie_execvpe(const char* file, char* const argv[], char* const envp[]);
IOSEXEC_PUBLIC int ie_execve(const char* path, char* const argv[], char* const envp[]); 

/*
 * If spawn.h was already included then we need these prototypes,
 * otherwise the defines below will let us use the prototypes from spawn.h
 */
#if defined(_SPAWN_H_) || defined(LIBIOSEXEC_INTERNAL)
# if defined(LIBIOSEXEC_INTERNAL) && !defined(_SPAWN_H_)
#  include <spawn.h>
# endif
IOSEXEC_PUBLIC int ie_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]);
IOSEXEC_PUBLIC int ie_posix_spawnp(pid_t *pid, const char *name, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]);
#endif

#if defined(_PWD_H_) || defined(LIBIOSEXEC_INTERNAL)
# if defined(LIBIOSEXEC_INTERNAL) && !defined(_PWD_H_)
#  include <pwd.h>
# endif
IOSEXEC_PUBLIC struct passwd *ie_getpwent(void);
IOSEXEC_PUBLIC struct passwd *ie_getpwnam(const char *name);
IOSEXEC_PUBLIC int ie_getpwnam_r(const char *name, struct passwd *pw, char *buf, size_t buflen, struct passwd **pwretp);
IOSEXEC_PUBLIC struct passwd *ie_getpwuid(uid_t uid);
IOSEXEC_PUBLIC int ie_getpwuid_r(uid_t uid, struct passwd *pw, char *buf, size_t buflen, struct passwd **pwretp);
IOSEXEC_PUBLIC int ie_setpassent(int stayopen);
IOSEXEC_PUBLIC void ie_setpwent(void);
IOSEXEC_PUBLIC void ie_endpwent(void);
IOSEXEC_PUBLIC char *ie_user_from_uid(uid_t, int);
#endif

#if defined(_GRP_H_) || defined(LIBIOSEXEC_INTERNAL)
# if defined(LIBIOSEXEC_INTERNAL) && !defined(_GRP_H_)
#  include <grp.h>
# endif
IOSEXEC_PUBLIC struct group *ie_getgrgid(gid_t gid);
IOSEXEC_PUBLIC int ie_getgrgid_r(gid_t gid, struct group *grp, char *buffer, size_t bufsize, struct group **result);
IOSEXEC_PUBLIC struct group *ie_getgrnam(const char *name);
IOSEXEC_PUBLIC int ie_getgrnam_r(const char *name, struct group *grp, char *buffer, size_t bufsize, struct group **result);
IOSEXEC_PUBLIC struct group *ie_getgrent(void);
IOSEXEC_PUBLIC void ie_setgrent(void);
IOSEXEC_PUBLIC void ie_endgrent(void);
IOSEXEC_PUBLIC char *ie_group_from_gid(gid_t, int);
#endif

#if defined(__APPLE__)
#  include <TargetConditionals.h>
#  if TARGET_OS_IPHONE
#    ifndef LIBIOSEXEC_INTERNAL
#      define execl ie_execl
#      define execle ie_execle
#      define execlp ie_execlp
#      define execv ie_execv
#      define execvp ie_execvp
#      define execvpe ie_execvpe
#      define execve ie_execve
#      define posix_spawn ie_posix_spawn
#      define posix_spawnp ie_posix_spawnp

#      define getpwent ie_getpwent
#      define getpwuid ie_getpwuid
#      define getpwuid_r ie_getpwuid_r
#      define getpwnam ie_getpwnam
#      define getpwnam_r ie_getpwnam_r
#      define setpassent ie_setpassent
#      define setpwent ie_setpwent
#      define endpwent ie_endpwent
#      define user_from_uid ie_user_from_uid

#      define getgrent ie_getgrent
#      define getgrgid ie_getgrgid
#      define getgrgid_r ie_getgrgid_r
#      define getgrnam ie_getgrnam
#      define getgrnam_r ie_getgrnam_r
#      define setgrent ie_setgrent
#      define endgrent ie_endgrent
#      define group_from_gid ie_group_from_gid
#    endif // LIBIOSEXEC_INTERNAL
#  endif // TARGET_OS_IPHONE
#endif // __APPLE__
  
#ifdef __cplusplus
}
#endif // __cplusplus

#endif // LIBIOSEXEC_H
