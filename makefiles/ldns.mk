ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += ldns
LDNS_COMMIT  := cb101c9c458b6a694676214dca7625442e5db8ff
LDNS_VERSION := 1.7.1+git20211107.$(shell echo $(LDNS_COMMIT) | cut -c -7)
DEB_LDNS_V   ?= $(LDNS_VERSION)

ldns-setup: setup
	$(call GITHUB_ARCHIVE,NLnetLabs,ldns,$(LDNS_COMMIT),$(LDNS_COMMIT))
	$(call EXTRACT_TAR,ldns-$(LDNS_COMMIT).tar.gz,ldns-$(LDNS_COMMIT),ldns)

ifneq ($(wildcard $(BUILD_WORK)/ldns/.build_complete),)
ldns:
	@echo "Using previously built ldns."
else
ldns: ldns-setup
	cd $(BUILD_WORK)/ldns && glibtoolize -ci && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-drill \
		--with-examples \
		--with-ssl="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--with-pyldns \
		--disable-dane-verify
	+$(MAKE) -C $(BUILD_WORK)/ldns
	+$(MAKE) -C $(BUILD_WORK)/ldns install \
		DESTDIR=$(BUILD_STAGE)/ldns
	+$(MAKE) -C $(BUILD_WORK)/ldns install \
		DESTDIR="$(BUILD_BASE)"
	$(call AFTER_BUILD)
endif

ldns-package: ldns-stage
	# ldns.mk Package Structure
	rm -rf $(BUILD_DIST)/{ldnsutils,libldns{3,-dev},python3-ldns}
	mkdir -p $(BUILD_DIST)/ldnsutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/libldns3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libldns-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include,share/man/man3} \
		$(BUILD_DIST)/python3-ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages

	# ldns.mk Prep ldnsutils
	cp -a $(BUILD_STAGE)/ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/ldnsutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/ldnsutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

        # ldns.mk Prep libldns3
	cp -a $(BUILD_STAGE)/ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libldns{.dylib,.1.dylib} $(BUILD_DIST)/libldns3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ldns.mk Prep libldns-dev
	cp -a $(BUILD_STAGE)/ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.dylib|python3) $(BUILD_DIST)/libldns-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libldns-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libldns-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# ldns.mk Prep python3-ldns
	cp -a $(BUILD_STAGE)/ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages $(BUILD_DIST)/python3-ldns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3

	# ldns.mk Sign
	$(call SIGN,ldnsutils,general.xml)
	$(call SIGN,libldns3,general.xml)
	$(call SIGN,libldns-dev,general.xml)
	$(call SIGN,python3-ldns,general.xml)

	# ldns.mk Make .debs
	$(call PACK,ldnsutils,DEB_LDNS_V)
	$(call PACK,libldns3,DEB_LDNS_V)
	$(call PACK,libldns-dev,DEB_LDNS_V)
	$(call PACK,python3-ldns,DEB_LDNS_V)

	# ldns.mk Build cleanup
	rm -rf $(BUILD_DIST)/{ldnsutils,libldns{3,-dev},python3-ldns}

.PHONY: ldns ldns-package
