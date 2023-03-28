ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

OPENSSL_CFBASE_VERSION := 3.0.8

openssl_CFbase-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.openssl.org/source/openssl-$(OPENSSL_CFBASE_VERSION).tar.gz{$(comma).asc})
	$(call PGP_VERIFY,openssl-$(OPENSSL_CFBASE_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssl-$(OPENSSL_CFBASE_VERSION).tar.gz,openssl-$(OPENSSL_CFBASE_VERSION),openssl)
ifeq (,$(findstring armv7,$(MEMO_TARGET)))
	touch $(BUILD_WORK)/openssl/0001-armv7-fix-atomic.patch.done
endif
ifneq (,$(findstring armv6,$(MEMO_TARGET)))
	# Do not build with atomics on armv6
	sed -i -e 's1#include <openssl/crypto.h>1#include <openssl/crypto.h>\n#define BROKEN_CLANG_ATOMICS1g' $(BUILD_WORK)/openssl/crypto/threads_pthread.c
endif
	$(call DO_PATCH,openssl,openssl,-p1)

ifneq ($(wildcard $(BUILD_WORK)/openssl/.build_complete),)
openssl_CFbase:
	@echo "Using previously built openssl."
else
openssl_CFbase: openssl-setup
	touch $(BUILD_WORK)/openssl/Configurations/15-openssl.conf
	@echo -e "my %targets = (\n\
		\"darwin64-armv7k\" => {\n\
			inherit_from     => [ \"darwin-common\" ],\n\
			CC               => add(\"-Wall\"),\n\
			cflags           => add(\"-arch armv7k\"),\n\
			lib_cppflags     => add(\"-DL_ENDIAN\"),\n\
			perlasm_scheme   => \"ios32\",\n\
			disable          => [ \"async\" ],\n\
		},\n\
		\"darwin64-armv7\" => {\n\
			inherit_from     => [ \"darwin-common\" ],\n\
			CC               => add(\"-Wall\"),\n\
			cflags           => add(\"-arch armv7\"),\n\
			lib_cppflags     => add(\"-DL_ENDIAN\"),\n\
			perlasm_scheme   => \"ios32\",\n\
			disable          => [ \"async\" ],\n\
		},\n\
		\"darwin64-armv6\" => {\n\
			inherit_from     => [ \"darwin-common\" ],\n\
			CC               => add(\"-Wall\"),\n\
			cflags           => add(\"-arch armv6\"),\n\
			lib_cppflags     => add(\"-DL_ENDIAN\"),\n\
			perlasm_scheme   => \"ios32\",\n\
			disable          => [ \"async\" ],\n\
		},\n\
		\"darwin64-arm64_32\" => {\n\
			inherit_from     => [ \"darwin-common\" ],\n\
			CC               => add(\"-Wall\"),\n\
			cflags           => add(\"-arch arm64_32\"),\n\
			lib_cppflags     => add(\"-DL_ENDIAN\"),\n\
			perlasm_scheme   => \"ios64\",\n\
		},\n\
	);" > $(BUILD_WORK)/openssl/Configurations/15-openssl.conf
	cd $(BUILD_WORK)/openssl && ./Configure \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--openssldir=$(MEMO_PREFIX)/etc/ssl \
		shared \
		no-tests \
		-DOPENSSL_NO_APPLE_CRYPTO_RANDOM \
		darwin64-$$(echo $(LLVM_TARGET) | cut -f1 -d-)
	+$(MAKE) -C $(BUILD_WORK)/openssl
	+$(MAKE) -C $(BUILD_WORK)/openssl install install_ssldirs \
		DESTDIR=$(BUILD_STAGE)/openssl
	$(call AFTER_BUILD,copy)
endif

openssl_CFbase-package:: DEB_OPENSSL_V ?= $(OPENSSL_CFBASE_VERSION)
openssl_CFbase-package: openssl-stage
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

.PHONY: openssl_CFbase openssl_CFbase-package
