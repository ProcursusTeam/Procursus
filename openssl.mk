ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += openssl
DOWNLOAD        += https://www.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz{,.asc}
OPENSSL_VERSION := 1.1.1f
DEB_OPENSSL_V   ?= $(OPENSSL_VERSION)

openssl-setup: setup
	$(call PGP_VERIFY,openssl-$(OPENSSL_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssl-$(OPENSSL_VERSION).tar.gz,openssl-$(OPENSSL_VERSION),openssl)
	touch $(BUILD_WORK)/openssl/Configurations/15-diatrus.conf
	@echo -e "my %targets = (\n\
		\"$(GNU_HOST_TRIPLE)\" => {\n\
			inherit_from     => [ \"darwin-common\", asm(\"aarch64_asm\") ],\n\
			CC               => \"$(CC)\",\n\
			cflags           => add(\"-O2 -fomit-frame-pointer -fno-common\"),\n\
			bn_ops           => \"SIXTY_FOUR_BIT_LONG RC4_CHAR\",\n\
			perlasm_scheme   => \"ios64\",\n\
			sys_id           => \"$(PLATFORM)\",\n\
		},\n\
	);" > $(BUILD_WORK)/openssl/Configurations/15-diatrus.conf

ifneq ($(wildcard $(BUILD_WORK)/openssl/.build_complete),)
openssl:
	@echo "Using previously built openssl."
else
openssl: openssl-setup
	cd $(BUILD_WORK)/openssl && ./Configure \
		--prefix=/usr \
		--openssldir=/etc/ssl \
		shared \
		$(GNU_HOST_TRIPLE)
	+$(MAKE) -C $(BUILD_WORK)/openssl
	+$(MAKE) -C $(BUILD_WORK)/openssl install_sw install_ssldirs \
		DESTDIR=$(BUILD_STAGE)/openssl
	+$(MAKE) -C $(BUILD_WORK)/openssl install_sw \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/openssl/.build_complete
endif

openssl-package: openssl-stage
	# openssl.mk Package Structure
	rm -rf $(BUILD_DIST)/{openssl,libssl{1.1,-dev}}
	mkdir -p $(BUILD_DIST)/{openssl/usr/bin,libssl{1.1,-dev}/usr/lib}

	# openssl.mk Prep libssl1.1
	cp -a $(BUILD_STAGE)/openssl/usr/lib $(BUILD_DIST)/libssl1.1/usr
	rm -rf $(BUILD_DIST)/libssl1.1/usr/lib/{lib{ssl,crypto}.{a,dylib},pkgconfig}

	# openssl.mk Prep libssl-dev
	cp -a $(BUILD_STAGE)/openssl/usr/lib/{lib{ssl,crypto}.{a,dylib},pkgconfig} $(BUILD_DIST)/libssl-dev/usr/lib
	
	# openssl.mk Prep openssl
	cp -a $(BUILD_STAGE)/openssl/etc $(BUILD_DIST)/openssl
	cp -a $(BUILD_STAGE)/openssl/usr/bin/* $(BUILD_DIST)/openssl/usr/bin
	
	# openssl.mk Sign
	$(call SIGN,libssl1.1,general.xml)
	$(call SIGN,openssl,general.xml)
	
	# openssl.mk Make .debs
	$(call PACK,libssl1.1,DEB_OPENSSL_V)
	$(call PACK,libssl-dev,DEB_OPENSSL_V)
	$(call PACK,openssl,DEB_OPENSSL_V)
	
	# openssl.mk Build cleanup
	rm -rf $(BUILD_DIST)/{openssl,libssl{1.1,-dev}}

.PHONY: openssl openssl-package
