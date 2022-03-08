ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libserf
LIBSERF_VERSION  := 1.3.9
DEB_LIBSERF_V    ?= $(LIBSERF_VERSION)-2

libserf-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://archive.apache.org/dist/serf/serf-$(LIBSERF_VERSION).tar.bz2
	$(call EXTRACT_TAR,serf-$(LIBSERF_VERSION).tar.bz2,serf-$(LIBSERF_VERSION),libserf)
	$(call DO_PATCH,libserf,libserf,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libserf/.build_complete),)
libserf:
	@echo "Using previously built libserf."
else
# Add krb5 after #948 merged
# GSSAPI=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
libserf: libserf-setup apr apr-util expat openssl
	cd $(BUILD_WORK)/libserf && scons \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/apr-1.0" \
		LINKFLAGS="$(LDFLAGS)" \
		OPENSSL=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		APR=$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		APU=$(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	scons -C $(BUILD_WORK)/libserf install \
		--install-sandbox=$(BUILD_STAGE)/libserf
	$(call AFTER_BUILD)
endif

libserf-package: libserf-stage
	# libserf.mk Package Structure
	rm -rf $(BUILD_DIST)/libserf-{1-1,dev}
	mkdir -p $(BUILD_DIST)/libserf-{1-1,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libserf.mk Prep libserf-1-1
	cp -a $(BUILD_STAGE)/libserf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libserf-1{,.1.3.9}.dylib $(BUILD_DIST)/libserf-1-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libserf.mk Prep libserf-dev
	cp -a $(BUILD_STAGE)/libserf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/* $(BUILD_DIST)/libserf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libserf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libserf-1.{a,1.dylib}} $(BUILD_DIST)/libserf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libserf.mk Sign
	$(call SIGN,libserf-1-1,general.xml)

	# libserf.mk Make .debs
	$(call PACK,libserf-1-1,DEB_LIBSERF_V)
	$(call PACK,libserf-dev,DEB_LIBSERF_V)

	# libserf.mk Build cleanup
	rm -rf $(BUILD_DIST)/libserf-{1-1,dev}

.PHONY: libserf libserf-package
