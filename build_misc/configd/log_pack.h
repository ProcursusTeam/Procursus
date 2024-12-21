#ifndef log_pack_h
#define log_pack_h

#include <TargetConditionals.h>
#include <Availability.h>
#include <CoreFoundation/CoreFoundation.h>
#include <dlfcn.h>
#include <dispatch/dispatch.h>
#include <os/base.h>
#include <os/log.h>
#include <os/signpost.h>

#define os_log_pack_size(fmt, ...) \
	_os_log_pack_size(sizeof(fmt))

#define os_log_pack_fill(pack, size, errno, fmt, ...) \
	_os_log_pack_fill(pack, size, errno, NULL, fmt)

#define os_log_pack_decl(name, size) \
	os_log_pack_t name = malloc(size)

typedef struct os_log_pack_s {
    uint64_t        olp_continuous_time;
    struct timespec olp_wall_time;
    const void     *olp_mh;
    const void     *olp_pc;
    const char     *olp_format;
    uint8_t         olp_data[0];
} os_log_pack_s, *os_log_pack_t;

API_AVAILABLE(macosx(10.12.4), ios(10.3), tvos(10.2), watchos(3.2))
size_t
_os_log_pack_size(size_t os_log_format_buffer_size);

API_AVAILABLE(macosx(10.12.4), ios(10.3), tvos(10.2), watchos(3.2))
uint8_t *
_os_log_pack_fill(os_log_pack_t pack, size_t size, int saved_errno, const void *dso, const char *fmt);

API_AVAILABLE(macosx(10.14), ios(12.0), tvos(12.0), watchos(5.0))
uint8_t *
_os_signpost_pack_fill(os_log_pack_t pack, size_t size,
        int saved_errno, const void *dso, const char *fmt,
        const char *spnm, os_signpost_id_t spid);

API_AVAILABLE(macosx(10.12.4), ios(10.3), tvos(10.2), watchos(3.2))
void
os_log_pack_send(os_log_pack_t pack, os_log_t log, os_log_type_t type);

API_AVAILABLE(macosx(10.14), ios(12.0), tvos(12.0), watchos(5.0))
void
_os_signpost_pack_send(os_log_pack_t pack, os_log_t h,
        os_signpost_type_t spty);
#endif
