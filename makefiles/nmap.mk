ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nmap
NMAP_VERSION := 7.92
DEB_NMAP_V   ?= $(NMAP_VERSION)

NMAP_MANPAGE_LANGS := de es fr hr hu it ja pl pt_BR pt_PT ro ru sk zh

nmap-setup: setup
	wget2 -q -nc -P $(BUILD_SOURCE) https://nmap.org/dist/nmap-$(NMAP_VERSION).tar.bz2
	$(call EXTRACT_TAR,nmap-$(NMAP_VERSION).tar.bz2,nmap-$(NMAP_VERSION),nmap)

ifneq ($(wildcard $(BUILD_WORK)/nmap/.build_complete),)
nmap:
	@echo "Using previously built nmap."
else
nmap: nmap-setup lua5.3 openssl pcre libssh2 libpcap
	cd $(BUILD_WORK)/nmap && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-liblua=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--without-nmap-update \
		--disable-universal \
		--without-zenmap \
		--without-ndiff
	sed -i 's|$$(CPP)|$$(CPP) $$(CPPFLAGS)|' $(BUILD_WORK)/nmap/{macosx/,}Makefile
	+$(MAKE) -C $(BUILD_WORK)/nmap
	+$(MAKE) -C $(BUILD_WORK)/nmap install -j1 \
		DESTDIR=$(BUILD_STAGE)/nmap
	$(call AFTER_BUILD)
endif

nmap-package: nmap-stage
	# nmap.mk Package Structure
	rm -rf $(BUILD_DIST)/n{map{,-common},cat}
	mkdir -p $(BUILD_DIST)/n{map-common,cat,map}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/n{map,cat}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for lang in '' $(NMAP_MANPAGE_LANGS); do \
		[ -f $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/ncat.1$(MEMO_MANPAGE_SUFFIX) ] && \
			mkdir -p $(BUILD_DIST)/ncat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1; \
		if [ -f $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/nmap.1$(MEMO_MANPAGE_SUFFIX) ] || [ -f $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/nping.1$(MEMO_MANPAGE_SUFFIX) ]; then \
			mkdir -p $(BUILD_DIST)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1; \
		fi; \
	done;

	# nmap.mk Prep nmap
	cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/n{map,ping} $(BUILD_DIST)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for lang in '' $(NMAP_MANPAGE_LANGS); do \
		if [ -d $(BUILD_DIST)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1 ]; then \
			if [ -f $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/nmap.1$(MEMO_MANPAGE_SUFFIX) ]; then \
				cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/nmap.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1; \
			fi; \
			if [ -f $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/nping.1$(MEMO_MANPAGE_SUFFIX) ]; then \
				cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/nping.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1; \
			fi; \
		fi; \
	done

	# nmap.mk Prep ncat
	cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ncat $(BUILD_DIST)/ncat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for lang in '' $(NMAP_MANPAGE_LANGS); do \
		[ -d $(BUILD_DIST)/ncat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1 ] && \
			cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/ncat.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/ncat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1 ; \
	done; true

	# nmap.mk Prep nmap-common
	cp -a $(BUILD_STAGE)/nmap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{ncat,nmap} $(BUILD_DIST)/nmap-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# nmap.mk Sign
	$(call SIGN,nmap,general.xml)
	$(call SIGN,ncat,general.xml)

	# nmap.mk Make .debs
	$(call PACK,nmap,DEB_NMAP_V)
	$(call PACK,ncat,DEB_NMAP_V)
	$(call PACK,nmap-common,DEB_NMAP_V)

	# nmap.mk Build cleanup
	rm -rf $(BUILD_DIST)/n{map{,-common},cat}

.PHONY: nmap nmap-package
