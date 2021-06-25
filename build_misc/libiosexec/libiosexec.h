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
#    endif // LIBIOSEXEC_INTERNAL
#  endif // TARGET_OS_IPHONE
#endif // __APPLE__
  
#ifdef __cplusplus
}
#endif // __cplusplus

#endif // LIBIOSEXEC_H
