ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += redis
REDIS_VERSION := 6.2.1
DEB_REDIS_V   ?= $(REDIS_VERSION)-2

###
# Dynamic link lua5.1 in the future.
###

redis-setup: setup
	$(call GITHUB_ARCHIVE,redis,redis,$(REDIS_VERSION),$(REDIS_VERSION))
	$(call EXTRACT_TAR,redis-$(REDIS_VERSION).tar.gz,redis-$(REDIS_VERSION),redis)
	$(call DO_PATCH,redis,redis,-p1)
	# Please don't ask why
	sed -i 's/$$.AR./$(AR)/g' $(BUILD_WORK)/redis/deps/hiredis/Makefile

	sed -i 's/PLAT= none/PLAT= macosx/' $(BUILD_WORK)/redis/deps/lua/Makefile
	sed -i 's/RANLIB=.*/RANLIB=$(RANLIB)/' $(BUILD_WORK)/redis/deps/lua/Makefile
	sed -i 's/AR=.*/AR=$(AR)/g' $(BUILD_WORK)/redis/deps/lua/src/Makefile
	sed -i 's/RANLIB=.*/RANLIB=$(RANLIB)/g' $(BUILD_WORK)/redis/deps/lua/src/Makefile

ifneq ($(wildcard $(BUILD_WORK)/redis/.build_complete),)
redis:
	@echo "Using previously built redis."
else
redis: redis-setup libjemalloc openssl
	+$(MAKE) -C $(BUILD_WORK)/redis V=1 \
		MALLOC=jemalloc \
		USE_SYSTEMD=no \
		uname_S=Darwin \
		uname_M=$(MEMO_ARCH) \
		PREFIX=$(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		BUILD_TLS=yes \
		USE_SYSTEM_JEMALLOC=yes	\
		USE_SYSTEM_LUA=no \
		install

	$(INSTALL) -Dm644 $(BUILD_WORK)/redis/redis.conf $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/etc/redis/redis.conf
	$(INSTALL) -Dm644 $(BUILD_WORK)/redis/sentinel.conf $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/etc/redis/sentinel.conf

	mkdir -p $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_MISC)/redis/*.plist $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/Library/LaunchDaemons

	mkdir -p $(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_MISC)/redis/redis-*-wrapper $(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec

	for file in $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/Library/LaunchDaemons/* \
		$(BUILD_STAGE)/redis/$(MEMO_PREFIX)/etc/redis/* \
		$(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/*; do \
			$(SED) -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $$file; \
			$(SED) -i 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $$file; \
	done

	touch $(BUILD_WORK)/redis/.build_complete
endif

redis-package: redis-stage
	# redis.mk Package Structure
	rm -rf $(BUILD_DIST)/redis-{server,tools,sentinel}
	mkdir -p $(BUILD_DIST)/redis-{sentinel,server,tools}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/redis-{server,sentinel}/$(MEMO_PREFIX)/{etc/redis,Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/libexec} \
		$(BUILD_DIST)/redis-server/$(MEMO_PREFIX)/var/lib/redis

	# redis.mk Prep redis-sentinel
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/redis-sentinel $(BUILD_DIST)/redis-sentinel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/etc/redis/sentinel.conf $(BUILD_DIST)/redis-sentinel/$(MEMO_PREFIX)/etc/redis
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/Library/LaunchDaemons/io.redis.redis-sentinel.plist $(BUILD_DIST)/redis-sentinel/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/redis-sentinel-wrapper $(BUILD_DIST)/redis-sentinel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec

	# redis.mk Prep redis-server
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/redis-server $(BUILD_DIST)/redis-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/etc/redis/redis.conf $(BUILD_DIST)/redis-server/$(MEMO_PREFIX)/etc/redis
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)/Library/LaunchDaemons/io.redis.redis-server.plist $(BUILD_DIST)/redis-server/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/redis-server-wrapper $(BUILD_DIST)/redis-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec

	# redis.mk Prep redis-tools
	cp -a $(BUILD_STAGE)/redis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/redis-{benchmark,check-aof,check-rdb,cli} $(BUILD_DIST)/redis-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# redis.mk Sign
	$(call SIGN,redis-sentinel,general.xml)
	$(call SIGN,redis-server,general.xml)
	$(call SIGN,redis-tools,general.xml)

	# redis.mk Make .debs
	$(call PACK,redis-sentinel,DEB_REDIS_V)
	$(call PACK,redis-server,DEB_REDIS_V)
	$(call PACK,redis-tools,DEB_REDIS_V)

	# redis.mk Build cleanup
	rm -rf $(BUILD_DIST)/redis-{sentinel,server,tools}

.PHONY: redis redis-package
