ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libtermkey
LIBTERMKEY_VERSION := 0.22
DEB_LIBTERMKEY_V   ?= $(LIBTERMKEY_VERSION)

libtermkey-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://www.leonerd.org.uk/code/libtermkey/libtermkey-$(LIBTERMKEY_VERSION).tar.gz
	$(call EXTRACT_TAR,libtermkey-$(LIBTERMKEY_VERSION).tar.gz,libtermkey-$(LIBTERMKEY_VERSION),libtermkey)
	$(call DO_PATCH,libtermkey,libtermkey)
	mkdir -p $(BUILD_WORK)/libtermkey/libtool
	echo -e "AC_INIT([dummy],[1.0])\n\
LT_INIT\n\
AC_PROG_LIBTOOL\n\
AC_OUTPUT" > $(BUILD_WORK)/libtermkey/libtool/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libtermkey/.build_complete),)
libtermkey:
	@echo "Using previously built libtermkey."
else
libtermkey: libtermkey-setup unibilium
	cd $(BUILD_WORK)/libtermkey/libtool && LIBTOOLIZE="$(LIBTOOLIZE) -i" autoreconf -fi
	cd $(BUILD_WORK)/libtermkey/libtool && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libtermkey \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		LIBTOOL="$(BUILD_WORK)/libtermkey/libtool/libtool" \
		CC="$(CC) $(CFLAGS)" \
		DEMOS=""
	+$(MAKE) -C $(BUILD_WORK)/libtermkey install PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_STAGE)/libtermkey"
	+$(MAKE) -C $(BUILD_WORK)/libtermkey install PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libtermkey/.build_complete
endif

libtermkey-package: libtermkey-stage
	# libtermkey.mk Package Structure
	rm -rf $(BUILD_DIST)/libtermkey{-dev,1}
	mkdir -p $(BUILD_DIST)/libtermkey{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtermkey.mk Prep libtermkey-dev
	cp -a $(BUILD_STAGE)/libtermkey/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libtermkey-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libtermkey/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libtermkey.{a,dylib}} $(BUILD_DIST)/libtermkey-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtermkey.mk Prep libtermkey1
	cp -a $(BUILD_STAGE)/libtermkey/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtermkey.1.dylib $(BUILD_DIST)/libtermkey1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtermkey.mk Sign
	$(call SIGN,libtermkey1,general.xml)

	# libtermkey.mk Make .debs
	$(call PACK,libtermkey-dev,DEB_LIBTERMKEY_V)
	$(call PACK,libtermkey1,DEB_LIBTERMKEY_V)

	# libtermkey.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtermkey{-dev,1}

.PHONY: libtermkey libtermkey-package
