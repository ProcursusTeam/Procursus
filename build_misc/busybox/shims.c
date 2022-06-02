/* Code placed here will be injected into busybox */

#ifndef HAVE_MEMRCHR
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>

char bb_common_bufsiz1_obj[1024];
char* bb_common_bufsiz1 = (char*)&bb_common_bufsiz1_obj;

/*
 * Reverse memchr()
 * Find the last occurrence of 'c' in the buffer 's' of size 'n'.
 */
void* memrchr(const void *s, int c, size_t n)
{
    const unsigned char *cp;

    if (n != 0) {
	cp = (unsigned char *)s + n;
	do {
	    if (*(--cp) == (unsigned char)c)
		return (void *)cp;
	} while (--n != 0);
    }
    return (void *)0;
}

int bb_errno = 0;


#undef sigemptyset
#undef sigfillset
#undef sigaddset
#undef sigdelset
#undef sigismember

int
__sigemptyset(set)
	sigset_t *set;
{
	*set = 0;
	return (0);
}

int
__sigfillset(set)
	sigset_t *set;
{
	*set = ~(sigset_t)0;
	return (0);
}

int
__sigaddset(set, signo)
	sigset_t *set;
	int signo;
{
	if ((signo < 0 ) || (signo > NSIG)) {
		errno = EINVAL;
		return(-1);
	}
	if (signo == 0)
		return(0);
	*set |= sigmask(signo);
	return (0);
}

int
__sigdelset(set, signo)
	sigset_t *set;
	int signo;
{
	if ((signo < 0 ) || (signo > NSIG)) {
		errno = EINVAL;
		return(-1);
	}
	if (signo == 0)
		return(0);
	*set &= ~sigmask(signo);
	return (0);
}

int
__sigismember(set, signo)
	const sigset_t *set;
	int signo;
{
	if ((signo < 0 ) || (signo > NSIG)) {
		errno = EINVAL;
		return(-1);
	}
	if (signo == 0)
		return(0);
	return ((*set & sigmask(signo)) != 0);
}

#endif /* HAVE_MEMRCHR */
