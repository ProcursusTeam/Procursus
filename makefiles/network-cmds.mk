ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS          += network-cmds
NETWORK-CMDS_VERSION := 624.100.5
DEB_NETWORK-CMDS_V   ?= $(NETWORK-CMDS_VERSION)

network-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,network_cmds,$(NETWORK-CMDS_VERSION),network_cmds-$(NETWORK-CMDS_VERSION))
	$(call EXTRACT_TAR,network_cmds-$(NETWORK-CMDS_VERSION).tar.gz,network_cmds-network_cmds-$(NETWORK-CMDS_VERSION),network-cmds)
	mkdir -p $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)/{{s,}bin,var/tmp/PanicDumps,Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/{{s,}bin,libexec,share/man/man{1,8}}}

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/network-cmds/include/{os,sys,firehose,arm,machine}
	cp -a $(MACOSX_SYSROOT)/usr/include/nlist.h $(BUILD_WORK)/network-cmds/include
	mkdir -p $(BUILD_WORK)/network-cmds/include/{net/{classq,},corecrypto}
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{libiosexec,stdlib,unistd,libutil}.h $(BUILD_WORK)/network-cmds/include
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/{internal,{base,log}_private.h,log.h} $(BUILD_WORK)/network-cmds/include/os
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/firehose/{firehose_types,tracepoint}_private.h $(BUILD_WORK)/network-cmds/include/firehose
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/arm/cpu_capabilities.h $(BUILD_WORK)/network-cmds/include/arm
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine/cpu_capabilities.h $(BUILD_WORK)/network-cmds/include/machine
	$(LN_S) $(BUILD_WORK)/network-cmds/include/{,System}

	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/net \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8020.101.4/bsd/net/{content_filter,packet_mangler,pktap,net_api_stats,if_ports_used,if_bridgevar,ntstat,if_llreach,route,if,if_var,if_mib,if_arp,if_media,radix,net_perf,if_6lowpan_var,if_bond_var,network_agent,if_fake_var,if_vlan_var,if_fake_var,bpf,lacp,if_bond_internal}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/net/pktsched \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8020.101.4/bsd/net/pktsched/pktsched{,_{cbq,fairq,fq_codel,hfsc,netem,priq,rmclass,fq_codel}}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/net/classq \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8020.101.4/bsd/net/classq/{classq,if_classq,classq_red,classq_blue,classq_rio,classq_sfb}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/netinet \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8020.101.4/bsd/netinet/{ip_dummynet,ip_flowid,mptcp_var,in_stat,in,tcp,tcp_var,ip_var,udp_var,if_ether,tcpip,icmp6,icmp_var,igmp_var,tcp_seq,tcp_fsm,in_var,in_pcb}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/netinet6 \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8020.101.4/bsd/netinet6/{ip6_var,in6_var,in6,nd6,mld6_var,in6_pcb,raw_ip6}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/sys \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8020.101.4/bsd/sys/{proc_info,socket,unpcb,kern_event,kern_control,socketvar,sys_domain,mbuf,sockio}.h
	@wget -q -nc -P$(BUILD_WORK)/network-cmds/include/mach \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8020.101.4/osfmk/mach/coalition.h
	@wget -q -nc -P$(BUILD_WORK)/network-cmds/include/corecrypto \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-8020.101.4/EXTERNAL_HEADERS/corecrypto/cc{,n,sha2,digest,_{config,error}}.h

	sed -i 's/#if INET6/#ifdef INET6/g' $(BUILD_WORK)/network-cmds/include/sys/sockio.h
	sed -i '/struct kevent_qos_s kqext_kev/d' $(BUILD_WORK)/network-cmds/include/sys/proc_info.h
	sed -i '1 i\#include <TargetConditionals.h>' $(BUILD_WORK)/network-cmds/{dnctl,frame_delay,ecnprobe,pktapctl,pktmnglr,mptcp_client}/*.c

ifneq ($(wildcard $(BUILD_WORK)/network-cmds/.build_complete),)
network-cmds:
	@echo "Using previously built network-cmds."
else
network-cmds: .SHELLFLAGS=-O extglob -c
network-cmds: network-cmds-setup libpcap
	set -e; \
	cd $(BUILD_WORK)/network-cmds; \
	for tproj in !(rarpd|ping|spray|rtadvd).tproj; do \
		tproj=$$(basename $$tproj .tproj); \
		echo $$tproj; \
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -o $$tproj $$tproj.tproj/!(ns).c ecnprobe/gmt2local.c -DPRIVATE=1 -DINET6 -DPLATFORM_$(BARE_PLATFORM) -D__APPLE_USE_RFC_3542=1 -DUSE_RFC2292BIS=1 -D__APPLE_API_OBSOLETE=1 -DTARGET_OS_EMBEDDED=1 -Dether_ntohost=_old_ether_ntohost -D_VA_LIST -D__OS_EXPOSE_INTERNALS__; \
	done; \
	for bin in cfilutil dnctl frame_delay pktapctl pktmnglr mptcp_client ecnprobe; do \
		echo $$bin; \
		[ "$$bin" = "ecnprobe" ] && LDFLAGS="$(LDFLAGS) -lpcap" || LDFLAGS="$(LDFLAGS)"; \
		$(CC) -Iinclude -DPRIVATE=1 $(CFLAGS) $$LDFLAGS $${bin}/*.c -o $${bin}/$${bin}; \
	done
	cp -a $(BUILD_WORK)/network-cmds/kdumpd $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	# FHS reminder:
	# bins with section 8 manpage => $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin (libexec for daemons)
	# bins with section 1 manpage => $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/network-cmds/{arp,dnctl/dnctl,frame_delay/frame_delay,ifconfig,ip6addrctl,kdumpd,mtest,ndp,ping6,pktapctl/pktapctl,route,rtsol,traceroute6,traceroute} $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/network-cmds/{pktmnglr/pktmnglr,cfilutil/cfilutil,ecnprobe/ecnprobe,mnc,mptcp_client/mptcp_client,netstat} $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/network-cmds/{dnctl,frame_delay,pktapctl,{arp,ifconfig,ip6addrctl,kdumpd,mtest,ndp,ping6,route,rtsol,traceroute6,traceroute}.tproj}/*.8 $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	# pktmnglr has no man page
	cp -a $(BUILD_WORK)/network-cmds/{cfilutil,ecnprobe,mptcp_client,{netstat,mnc}.tproj}/*.1 $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cd $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin; \
	for bin in ifconfig ip6addrctl netstat ping6 route rtsol; do \
		$(LN_S) ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/$$bin $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)/sbin; \
	done
	$(LN_S) ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/ping6 $(BUILD_STAGE)/network-cmds/bin
	sed -e 's|/var|$(MEMO_PREFIX)/var|g' -e 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' < $(BUILD_WORK)/network-cmds/kdumpd.tproj/com.apple.kdumpd.plist > $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons/com.apple.kdumpd.plist
	chmod 1755 $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)/var/tmp/PanicDumps
	$(call AFTER_BUILD)
endif

network-cmds-package: network-cmds-stage
	# network-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/network-cmds

	# network-cmds.mk Prep network-cmds
	cp -a $(BUILD_STAGE)/network-cmds $(BUILD_DIST)

	# network-cmds.mk Sign
	$(call SIGN,network-cmds,general.xml)

	# network-cmds.mk Permissions
	$(FAKEROOT) chown nobody:nogroup $(BUILD_DIST)/network-cmds/$(MEMO_PREFIX)/var/tmp/PanicDumps

	# network-cmds.mk Make .debs
	$(call PACK,network-cmds,DEB_NETWORK-CMDS_V)

	# network-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/network-cmds

.PHONY: network-cmds network-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
