ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(SSH_STRAP),1)
STRAPPROJECTS   += openssl3
else # ($(SSH_STRAP),1)
SUBPROJECTS     += openssl3
endif # ($(SSH_STRAP),1)
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS     += openssl3
endif
OPENSSL3_VERSION := 3.0.0-beta1
DEB_OPENSSL3_V   ?= $(OPENSSL3_VERSION)

openssl3-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.openssl.org/source/openssl-$(OPENSSL3_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,openssl-$(OPENSSL3_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssl-$(OPENSSL3_VERSION).tar.gz,openssl-$(OPENSSL3_VERSION),openssl3)

ifneq ($(wildcard $(BUILD_WORK)/openssl3/.build_complete),)
openssl3:
	@echo "Using previously built openssl3."
else
openssl3: openssl3-setup
	cd $(BUILD_WORK)/openssl3 && ./Configure \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--openssldir=$(MEMO_PREFIX)/etc/ssl \
		shared \
		no-tests \
		darwin64-$$(echo $(LLVM_TARGET) | cut -f1 -d-)
	+$(MAKE) -C $(BUILD_WORK)/openssl3
	+$(MAKE) -C $(BUILD_WORK)/openssl3 install_sw install_ssldirs \
		DESTDIR=$(BUILD_STAGE)/openssl3
#	+$(MAKE) -C $(BUILD_WORK)/openssl3 install_sw \
#		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/openssl3/.build_complete
endif

openssl3-package: openssl3-stage
	# openssl3.mk Package Structure
	rm -rf $(BUILD_DIST)/{openssl,libssl{3,-dev}}
	mkdir -p $(BUILD_DIST)/{openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin,libssl{3,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib}

	# openssl3.mk Prep libssl3
	cp -a $(BUILD_STAGE)/openssl3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{*.3.dylib,engines-3,ossl-modules} $(BUILD_DIST)/libssl3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openssl3.mk Prep libssl-dev
	cp -a $(BUILD_STAGE)/openssl3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{lib{ssl,crypto}.{a,dylib},pkgconfig} $(BUILD_DIST)/libssl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/openssl3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libssl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# openssl3.mk Prep openssl3
	cp -a $(BUILD_STAGE)/openssl3/$(MEMO_PREFIX)/etc $(BUILD_DIST)/openssl/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/openssl3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/* $(BUILD_DIST)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# openssl3.mk Sign
	$(call SIGN,libssl3,general.xml)
	$(call SIGN,openssl,general.xml)

	# openssl3.mk Make .debs
	$(call PACK,libssl3,DEB_OPENSSL3_V)
	$(call PACK,libssl-dev,DEB_OPENSSL3_V)
	$(call PACK,openssl,DEB_OPENSSL3_V)

	# openssl3.mk Build cleanup
	rm -rf $(BUILD_DIST)/{openssl,libssl{3,-dev}}

.PHONY: openssl3 openssl3-package
