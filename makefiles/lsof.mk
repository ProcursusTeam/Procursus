ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS  += lsof
LSOF_VERSION := 62
DEB_LSOF_V   ?= $(LSOF_VERSION)

lsof-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/lsof/lsof-$(LSOF_VERSION).tar.gz
	$(call EXTRACT_TAR,lsof-$(LSOF_VERSION).tar.gz,lsof-$(LSOF_VERSION),lsof)
	mkdir -p $(BUILD_STAGE)/lsof/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,share/man/man8}
	$(SED) -i 's/lcurses/lncursesw/' $(BUILD_WORK)/lsof/lsof/Configure

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/lsof/lsof/include/rpc

	wget -q -nc -P $(BUILD_WORK)/lsof/lsof/include/rpc \
		https://opensource.apple.com/source/Libinfo/Libinfo-538/rpc.subproj/pmap_prot.h

ifneq ($(wildcard $(BUILD_WORK)/lsof/.build_complete),)
lsof:
	@echo "Using previously built lsof."
else
lsof: lsof-setup network-cmds-setup ncurses
	cd $(BUILD_WORK)/lsof/lsof; \
	DARWIN_BASE=libproc LSOF_VERS=1700 \
		LSOF_INCLUDE=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		./Configure -n darwin
	unlink $(BUILD_WORK)/lsof/lsof/dchannel.c && touch $(BUILD_WORK)/lsof/lsof/dchannel.c
	echo -e "#include \"lsof.h\"\n \
	void process_channel(int pid, int32_t fd){}" > $(BUILD_WORK)/lsof/lsof/dchannel.c
	cd $(BUILD_WORK)/lsof/lsof; \
	$(MAKE) \
		CC=$(CC) \
		AR="$(AR) cr \$${LIB} \$${OBJ}" \
		RANLIB="$(RANLIB) \$${LIB}" \
		RC_CFLAGS="$(CFLAGS) -DHASUTMPX -isystem $(BUILD_WORK)/network-cmds/include -isystem $(BUILD_WORK)/lsof/lsof/include -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib"
	cp -a $(BUILD_WORK)/lsof/lsof/lsof $(BUILD_STAGE)/lsof/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/lsof/lsof/lsof.8 $(BUILD_STAGE)/lsof/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	touch $(BUILD_WORK)/lsof/.build_complete
endif

lsof-package: lsof-stage
	# lsof.mk Package Structure
	rm -rf $(BUILD_DIST)/lsof

	# lsof.mk Prep lsof
	cp -a $(BUILD_STAGE)/lsof $(BUILD_DIST)

	# lsof.mk Sign
	$(call SIGN,lsof,general.xml)

	# lsof.mk Make .debs
	$(call PACK,lsof,DEB_LSOF_V)

	# lsof.mk Build cleanup
	rm -rf $(BUILD_DIST)/lsof

.PHONY: lsof lsof-package

endif