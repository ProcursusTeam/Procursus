ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(SSH_STRAP),1)
STRAPPROJECTS   += openssl1
else # ($(SSH_STRAP),1)
SUBPROJECTS     += openssl1
endif # ($(SSH_STRAP),1)
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS     += openssl1
endif
OPENSSL1_VERSION := 1.1.1k
DEB_OPENSSL1_V   ?= $(OPENSSL1_VERSION)-1

###
#
# TODO: change SSL Scheme to darwin64-arm64 when openssl adds proper m1 support.
#
###

ifneq (,$(findstring aarch64,$(GNU_HOST_TRIPLE)))
	SSL_SCHEME := aarch64-apple-darwin
else ifneq (,$(findstring arm,$(GNU_HOST_TRIPLE)))
	SSL_SCHEME := arm-apple-darwin
else ifneq (,$(findstring x86_64,$(GNU_HOST_TRIPLE)))
	SSL_SCHEME := darwin64-x86_64-cc
else
	$(error Host triple $(GNU_HOST_TRIPLE) isn't supported)
endif

openssl1-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.openssl.org/source/openssl-$(OPENSSL1_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,openssl-$(OPENSSL1_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssl-$(OPENSSL1_VERSION).tar.gz,openssl-$(OPENSSL1_VERSION),openssl1)
	touch $(BUILD_WORK)/openssl1/Configurations/15-diatrus.conf
	@echo -e "my %targets = (\n\
		\"aarch64-apple-darwin\" => {\n\
			inherit_from     => [ \"darwin-common\", asm(\"aarch64_asm\") ],\n\
			CC               => \"$(CC)\",\n\
			cflags           => add(\"-O2 -fomit-frame-pointer -fno-common\"),\n\
			bn_ops           => \"SIXTY_FOUR_BIT_LONG RC4_CHAR\",\n\
			perlasm_scheme   => \"ios64\",\n\
			sys_id           => \"$(PLATFORM)\",\n\
		},\n\
		\"arm-apple-darwin\" => {\n\
			inherit_from     => [ \"darwin-common\", asm(\"armv4_asm\") ],\n\
			CC               => \"$(CC)\",\n\
			cflags           => add(\"-O2 -fomit-frame-pointer -fno-common\"),\n\
			perlasm_scheme   => \"ios32\",\n\
			sys_id           => \"$(PLATFORM)\",\n\
		},\n\
	);" > $(BUILD_WORK)/openssl1/Configurations/15-diatrus.conf

ifneq ($(wildcard $(BUILD_WORK)/openssl1/.build_complete),)
openssl1:
	@echo "Using previously built openssl1."
else
openssl1: openssl1-setup
	cd $(BUILD_WORK)/openssl1 && ./Configure \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--openssldir=$(MEMO_PREFIX)/etc/ssl \
		shared \
		$(SSL_SCHEME)
	+$(MAKE) -C $(BUILD_WORK)/openssl1
	+$(MAKE) -C $(BUILD_WORK)/openssl1 install_sw install_ssldirs \
		DESTDIR=$(BUILD_STAGE)/openssl1
	$(call AFTER_BUILD,copy)
endif

openssl1-package: openssl1-stage
	# openssl1.mk Package Structure
	rm -rf $(BUILD_DIST)/libssl1.1
	mkdir -p $(BUILD_DIST)/libssl1.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# openssl1.mk Prep libssl1.1
	cp -a $(BUILD_STAGE)/openssl1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/libssl1.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	rm -rf $(BUILD_DIST)/libssl1.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{lib{ssl,crypto}.{a,dylib},pkgconfig}

	# openssl1.mk Sign
	$(call SIGN,libssl1.1,general.xml)

	# openssl1.mk Make .debs
	$(call PACK,libssl1.1,DEB_OPENSSL1_V)
	
	# openssl1.mk Build cleanup
	rm -rf $(BUILD_DIST)/libssl1.1

.PHONY: openssl1 openssl1-package
