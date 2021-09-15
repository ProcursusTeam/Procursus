ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += openssl
OPENSSL_VERSION := 3.0.0
DEB_OPENSSL_V   ?= $(OPENSSL_VERSION)

openssl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,openssl-$(OPENSSL_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssl-$(OPENSSL_VERSION).tar.gz,openssl-$(OPENSSL_VERSION),openssl)
	$(call DO_PATCH,openssl,openssl,-p1)

ifneq ($(wildcard $(BUILD_WORK)/openssl/.build_complete),)
openssl:
	@echo "Using previously built openssl."
else
openssl: openssl-setup
	cd $(BUILD_WORK)/openssl && ./Configure \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--openssldir=$(MEMO_PREFIX)/etc/ssl \
		shared \
		no-tests \
		darwin64-$$(echo $(LLVM_TARGET) | cut -f1 -d-)
	+$(MAKE) -C $(BUILD_WORK)/openssl
	+$(MAKE) -C $(BUILD_WORK)/openssl install install_ssldirs \
		DESTDIR=$(BUILD_STAGE)/openssl
	$(call AFTER_BUILD,copy)
endif

openssl-package: openssl-stage
	# openssl.mk Package Structure
	rm -rf $(BUILD_DIST)/{openssl,libssl{3,-dev,-doc}}
	mkdir -p $(BUILD_DIST)/{openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin,libssl{3,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib} \
		$(BUILD_DIST)/libssl-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/
	
	# openssl.mk Prep libssl3
	cp -a $(BUILD_STAGE)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{*.3.dylib,engines-3,ossl-modules} $(BUILD_DIST)/libssl3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# openssl.mk Prep libssl-dev
	cp -a $(BUILD_STAGE)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{lib{ssl,crypto}.{a,dylib},pkgconfig} $(BUILD_DIST)/libssl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libssl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# openssl.mk Prep libssl-doc
	cp -a $(BUILD_STAGE)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/libssl-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/
	
	# openssl.mk Prep openssl
	cp -a $(BUILD_STAGE)/openssl/$(MEMO_PREFIX)/etc $(BUILD_DIST)/openssl/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/* $(BUILD_DIST)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# openssl.mk Sign
	$(call SIGN,libssl3,general.xml)
	$(call SIGN,openssl,general.xml)
	
	# openssl.mk Make .debs
	$(call PACK,libssl3,DEB_OPENSSL_V)
	$(call PACK,libssl-dev,DEB_OPENSSL_V)
	$(call PACK,libssl-doc,DEB_OPENSSL_V)
	$(call PACK,openssl,DEB_OPENSSL_V)
	
	# openssl.mk Build cleanup
	rm -rf $(BUILD_DIST)/{openssl,libssl{3,-dev,-doc}}

.PHONY: openssl openssl-package
