ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS 	 += ttyrec
TTYREC_VERSION := 1.0.8
DEB_TTYREC_V   ?= $(TTYREC_VERSION)

ttyrec-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://0xcc.net/ttyrec/ttyrec-$(TTYREC_VERSION).tar.gz
	$(call EXTRACT_TAR,ttyrec-$(TTYREC_VERSION).tar.gz,ttyrec-$(TTYREC_VERSION),ttyrec)
	$(call DO_PATCH,ttyrec,ttyrec,-p1)

ifneq ($(wildcard $(BUILD_WORK)/ttyrec/.build_complete),)
ttyrec:
	@echo "Using previously built ttyrec."
else
ttyrec: ttyrec-setup
	+$(MAKE) -C $(BUILD_WORK)/ttyrec CC="$(CC)" CFLAGS="$(CFLAGS) -DHAVE_openpty"
	mkdir -p $(BUILD_STAGE)/ttyrec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	+$(MAKE) -C $(BUILD_WORK)/ttyrec install \
		DESTDIR="$(BUILD_STAGE)/ttyrec"
	cp $(BUILD_WORK)/ttyrec/tty{play,rec,time}.1 $(BUILD_STAGE)/ttyrec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	touch $(BUILD_WORK)/ttyrec/.build_complete
endif

ttyrec-package: ttyrec-stage
	# ttyrec.mk Package Structure
	rm -rf $(BUILD_DIST)/ttyrec
	mkdir -p $(BUILD_DIST)/ttyrec

	# ttyrec.mk Prep ttyrec
	cp -a $(BUILD_STAGE)/ttyrec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/ttyrec

	# ttyrec.mk Sign
	$(call SIGN,ttyrec,general.xml)

	# ttyrec.mk Make .debs
	$(call PACK,ttyrec,DEB_TTYREC_V)

	# ttyrec.mk Build cleanup
	rm -rf $(BUILD_DIST)/ttyrec

.PHONY: ttyrec ttyrec-package
