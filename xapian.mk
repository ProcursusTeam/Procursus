ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xapian
XAPIAN_VERSION := 1.4.17
DEB_XAPIAN_V   ?= $(XAPIAN_VERSION)

xapian-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://oligarchy.co.uk/xapian/$(XAPIAN_VERSION)/xapian-core-$(XAPIAN_VERSION).tar.xz
	$(call EXTRACT_TAR,xapian-core-$(XAPIAN_VERSION).tar.xz,xapian-core-$(XAPIAN_VERSION),xapian)

ifneq ($(wildcard $(BUILD_WORK)/xapian/.build_complete),)
xapian:
	@echo "Using previously built xapian."
else
xapian: xapian-setup uuid
	cd $(BUILD_WORK)/xapian && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--enable-shared=yes \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/xapian
	+$(MAKE) -C $(BUILD_WORK)/xapian install \
		DESTDIR=$(BUILD_STAGE)/xapian
	+$(MAKE) -C $(BUILD_WORK)/xapian install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xapian/.build_complete
endif

xapian-package: xapian-stage
	# xapian.mk Package Structure
	rm -rf $(BUILD_DIST)/libxapian{30,-dev} \
		$(BUILD_DIST)/xapian-{examples,tools}
	mkdir -p $(BUILD_DIST)/libxapian30/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
		$(BUILD_DIST)/libxapian-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{bin,include,lib,share/man/man1} \
		$(BUILD_DIST)/xapian-{examples,tools}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{bin,share/man/man1}
	
	# xapian.mk Prep libxapian30
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libxapian.30.dylib $(BUILD_DIST)/libxapian30/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# xapian.mk Prep libxapian-dev
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin/xapian-config $(BUILD_DIST)/libxapian-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/libxapian-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/!(libxapian.30.dylib) $(BUILD_DIST)/libxapian-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/aclocal $(BUILD_DIST)/libxapian-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man/man1/xapian-config.1 $(BUILD_DIST)/libxapian-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man/man1
	
	# xapian.mk Prep xapian-examples
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin/simple{expand,index,search} $(BUILD_DIST)/xapian-examples/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	
	# xapian.mk Prep xapian-tools
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin/{quest,copydatabase,xapian-{check,compact,delve,metadata,pos,progsrv,replicate{,-server},tcpsrv}} $(BUILD_DIST)/xapian-tools/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	cp -a $(BUILD_STAGE)/xapian/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man/man1/{copydatabase,quest,xapian-{check,compact,delve,metadata,pos,progsrv,replicate{,-server},tcpsrv}}.1 $(BUILD_DIST)/xapian-tools/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man/man1
	
	# xapian.mk Sign
	$(call SIGN,libxapian30,general.xml)
	$(call SIGN,libxapian-dev,general.xml)
	$(call SIGN,xapian-examples,general.xml)
	$(call SIGN,xapian-tools,general.xml)
	
	# xapian.mk Make .debs
	$(call PACK,libxapian30,DEB_XAPIAN_V)
	$(call PACK,libxapian-dev,DEB_XAPIAN_V)
	$(call PACK,xapian-examples,DEB_XAPIAN_V)
	$(call PACK,xapian-tools,DEB_XAPIAN_V)
	
	# xapian.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxapian{30,-dev} \
		$(BUILD_DIST)/xapian-{examples,tools}

.PHONY: xapian xapian-package
