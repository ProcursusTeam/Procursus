ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libuv1
LIBUV1_VERSION := 1.41.0
DEB_LIBUV1_V   ?= $(LIBUV1_VERSION)-1

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
LIBUV1_CONFIGURE_ARGS := LDFLAGS="$$LDFLAGS -liosexec"
else
LIBUV1_CONFIGURE_ARGS :=
endif

libuv1-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dist.libuv.org/dist/v$(LIBUV1_VERSION)/libuv-v$(LIBUV1_VERSION).tar.gz
	$(call EXTRACT_TAR,libuv-v$(LIBUV1_VERSION).tar.gz,libuv-v$(LIBUV1_VERSION),libuv1)
	# The libuv devs are idiots and this sed call can be removed when they fix this issue.
	# See https://github.com/libuv/libuv/issues/2975
	$(SED) -i '/#include <unistd.h>/a #include "darwin-stub.h"' $(BUILD_WORK)/libuv1/src/unix/darwin.c
	$(SED) -i 's,Versions/A/CoreFoundation,CoreFoundation,' $(BUILD_WORK)/libuv1/src/unix/darwin.c
	$(SED) -i 's,Versions/A/IOKit,IOKit,' $(BUILD_WORK)/libuv1/src/unix/darwin.c
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
		$(SED) -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_WORK)/libuv1/src/unix/process.c
endif

ifneq ($(wildcard $(BUILD_WORK)/libuv1/.build_complete),)
libuv1:
	@echo "Using previously built libuv1."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
libuv1: libuv1-setup libiosexec
else
libuv1: libuv1-setup
endif
	if ! [ -f $(BUILD_WORK)/libuv1/configure ]; then \
		cd $(BUILD_WORK)/libuv1 && ./autogen.sh; \
	fi
	cd $(BUILD_WORK)/libuv1 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(LIBUV1_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/libuv1
	+$(MAKE) -C $(BUILD_WORK)/libuv1 install \
		DESTDIR="$(BUILD_STAGE)/libuv1"
	+$(MAKE) -C $(BUILD_WORK)/libuv1 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libuv1/.build_complete
endif

libuv1-package: libuv1-stage
	# libuv1.mk Package Structure
	rm -rf $(BUILD_DIST)/libuv1{,-dev}
	mkdir -p $(BUILD_DIST)/libuv1{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libuv1.mk Prep libuv1
	cp -a $(BUILD_STAGE)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuv.1.dylib $(BUILD_DIST)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libuv1.mk Prep libuv1-dev
	cp -a $(BUILD_STAGE)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libuv1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libuv.{a,dylib},pkgconfig} $(BUILD_DIST)/libuv1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libuv1.mk Sign
	$(call SIGN,libuv1,general.xml)

	# libuv1.mk Make .debs
	$(call PACK,libuv1,DEB_LIBUV1_V)
	$(call PACK,libuv1-dev,DEB_LIBUV1_V)

	# libuv1.mk Build cleanup
	rm -rf $(BUILD_DIST)/libuv1{,-dev}

.PHONY: libuv1 libuv1-package
