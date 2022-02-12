ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS          += network-cmds
NETWORK-CMDS_VERSION := 624
DEB_NETWORK-CMDS_V   ?= $(NETWORK-CMDS_VERSION)

network-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,network_cmds,$(NETWORK-CMDS_VERSION),network_cmds-$(NETWORK-CMDS_VERSION))
	$(call EXTRACT_TAR,network_cmds-$(NETWORK-CMDS_VERSION).tar.gz,network_cmds-network_cmds-$(NETWORK-CMDS_VERSION),network-cmds)
	mkdir -p $(BUILD_STAGE)/network-cmds/{{s,}bin,usr/{{s,}bin,libexec}}

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/network-cmds/include/sys
	cp -a $(MACOSX_SYSROOT)/usr/include/nlist.h $(BUILD_WORK)/network-cmds/include
	mkdir -p $(BUILD_WORK)/network-cmds/include/net/{classq,}
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{libiosexec,stdlib,unistd}.h $(BUILD_WORK)/network-cmds/include

	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/net \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8019.41.5/bsd/net/{net_api_stats,if_ports_used,if_bridgevar,ntstat,if_llreach,route,if,if_var,if_mib,if_arp,if_media,radix,net_perf,if_6lowpan_var,if_bond_var,network_agent,if_fake_var,if_vlan_var,if_fake_var,lacp,if_bond_internal}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/net/pktsched \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8019.41.5/bsd/net/pktsched/pktsched{,_{cbq,fairq,fq_codel,hfsc,netem,priq,rmclass}}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/net/classq \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8019.41.5/bsd/net/classq/{classq,if_classq,classq_red,classq_blue,classq_rio,classq_sfb}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/netinet \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8019.41.5/bsd/netinet/{mptcp_var,in_stat,in,tcp,tcp_var,ip_var,udp_var,if_ether,tcpip,icmp_var,igmp_var,tcp_seq,tcp_fsm,in_var,in_pcb}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/netinet6 \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8019.41.5/bsd/netinet6/{ip6_var,in6_var,in6,nd6,mld6_var,in6_pcb,raw_ip6}.h
	@wget -q -nc -P $(BUILD_WORK)/network-cmds/include/sys \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8019.41.5/bsd/sys/{proc_info,socket,unpcb,kern_event,kern_control,socketvar,sys_domain,mbuf,sockio}.h
	@wget -q -nc -P$(BUILD_WORK)/network-cmds/include/mach \
		https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8019.41.5/osfmk/mach/coalition.h

	sed -i 's/#if INET6/#ifdef INET6/g' $(BUILD_WORK)/network-cmds/include/sys/sockio.h
	sed -i 's|struct kevent_qos_s kqext_kev|struct kevent_qos_s { \n\
             uint64_t        ident;          /* identifier for this event */ \n\
             int16_t         filter;         /* filter for event */ \n\
             uint16_t        flags;          /* general flags */ \n\
             uint32_t        qos;            /* quality of service when servicing event */ \n\
             uint64_t        udata;          /* opaque user data identifier */ \n\
             uint32_t        fflags;         /* filter-specific flags */ \n\
             uint32_t        xflags;         /* extra filter-specific flags */ \n\
             int64_t         data;           /* filter-specific data */ \n\
             uint64_t        ext[4];         /* filter-specific extensions */ \n\
     }|g' $(BUILD_WORK)/network-cmds/include/sys/proc_info.h

ifneq ($(wildcard $(BUILD_WORK)/network-cmds/.build_complete),)
network-cmds:
	@echo "Using previously built network-cmds."
else
network-cmds: .SHELLFLAGS=-O extglob -c
network-cmds: network-cmds-setup
	cd $(BUILD_WORK)/network-cmds; \
	for tproj in !(ping|rtadvd|rarpd|spray).tproj; do \
		tproj=$$(basename $$tproj .tproj); \
		echo $$tproj; \
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -o $$tproj $$tproj.tproj/!(ns).c ecnprobe/gmt2local.c -DPRIVATE -DINET6 -DPLATFORM_$(BARE_PLATFORM) -D__APPLE_USE_RFC_3542=1 -DUSE_RFC2292BIS=1 -D__APPLE_API_OBSOLETE=1 -DTARGET_OS_EMBEDDED=1 -Dether_ntohost=_old_ether_ntohost; \
	done
	cp -a $(BUILD_WORK)/network-cmds/kdumpd $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_WORK)/network-cmds/{arp,ndp,traceroute,mnc,mtest,traceroute6,ifconfig,ip6addrctl,netstat,ping6,route,rtsol} $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cd $(BUILD_STAGE)/network-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin; \
	for bin in ifconfig ip6addrctl netstat ping6 route rtsol; do \
		$(LN_S) ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/$$bin $(BUILD_STAGE)/network-cmds/sbin; \
	done
	$(LN_S) ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/ping6 $(BUILD_STAGE)/network-cmds/bin
	$(call AFTER_BUILD)
endif

network-cmds-package: network-cmds-stage
	# network-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/network-cmds

	# network-cmds.mk Prep network-cmds
	cp -a $(BUILD_STAGE)/network-cmds $(BUILD_DIST)

	# network-cmds.mk Sign
	$(call SIGN,network-cmds,general.xml)

	# network-cmds.mk Make .debs
	$(call PACK,network-cmds,DEB_NETWORK-CMDS_V)

	# network-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/network-cmds

.PHONY: network-cmds network-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
