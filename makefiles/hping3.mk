ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += hping3
HPING3_VERSION := 3.a2.ds2-10
HPING3_COMMIT  := 3547c7691742c6eaa31f8402e0ccbb81387c1b99
DEB_HPING3_V   ?= $(HPING3_VERSION)

hping3-setup: setup
	$(call GITHUB_ARCHIVE,antirez,hping,$(HPING3_COMMIT),$(HPING3_COMMIT))
	$(call EXTRACT_TAR,hping-$(HPING3_COMMIT).tar.gz,hping-$(HPING3_COMMIT),hping3)
	echo -e '#define OSTYPE_DARWIN\n#define __SYSTYPE_H' > $(BUILD_WORK)/hping3/systype.h
	sed -i 's|#include <unistd.h>|#include <unistd.h>\n#include <mach/mach.h>|g' $(BUILD_WORK)/hping3/script.c
	mkdir -p $(BUILD_STAGE)/hping3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,share/man/{,fr}/man8}

ifneq ($(wildcard $(BUILD_WORK)/hping3/.build_complete),)
hping3:
	@echo "Using previously built hping3."
else
hping3: hping3-setup tcl libpcap
	cd $(BUILD_WORK)/hping3; \
		$(LN_S) $(TARGET_SYSROOT)/usr/include/architecture/byte_order.h $(BUILD_WORK)/hping3/byteorder.h; \
		$(CC) $(CFLAGS) $(LDFLAGS) -fcommon -DUSE_TCL -D__LITTLE_ENDIAN_BITFIELD -lz -framework CoreFoundation {adbuf,antigetopt,apd,apdutils,ars,arsglue,binding,cksum,datafiller,datahandler,display_ipopt,gethostname,getifname,getlhs,getusec,hex,hstring,if_promisc,interface,ip_opt_build,libpcap_stuff,listen,logicmp,main,memlock,memlockall,memstr,memunlock,memunlockall,opensockraw,parseoptions,random,rapd,relid,resolve,rtt,sbignum-tables,sbignum,scan,script,send,sendhcmp,sendicmp,sendip,sendip_handler,sendrawip,sendtcp,sendudp,signal,sockopt,split,statistics,strlcpy,usage,version,waitpacket}.c -ltcl8.6 -lpcap -o $(BUILD_STAGE)/hping3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/hping3;
		$(INSTALL) -m644 $(BUILD_WORK)/hping3/docs/hping3.8 $(BUILD_STAGE)/hping3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8;
		$(INSTALL) -m644 $(BUILD_WORK)/hping3/docs/french/hping2-fr.8 $(BUILD_STAGE)/hping3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/fr/man8/hping3.8
	$(call AFTER_BUILD)
endif

hping3-package: hping3-stage
	# hping3.mk Package Structure
	rm -rf $(BUILD_DIST)/hping3

	# hping3.mk Prep hping3
	cp -a $(BUILD_STAGE)/hping3 $(BUILD_DIST)

	# hping3.mk Sign
	$(call SIGN,hping3,general.xml)

	# hping3.mk Make .debs
	$(call PACK,hping3,DEB_HPING3_V)

	# hping3.mk Build cleanup
	rm -rf $(BUILD_DIST)/hping3

.PHONY: hping3 hping3-package
