ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq ($(MEMO_TARGET),darwin-\*)
STRAPPROJECTS    += readline
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS      += readline
endif # ($(MEMO_TARGET),darwin-\*)
READLINE_VERSION := 8.1
DEB_READLINE_V   ?= $(READLINE_VERSION)

readline-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/readline/readline-$(READLINE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,readline-$(READLINE_VERSION).tar.gz)
	$(call EXTRACT_TAR,readline-$(READLINE_VERSION).tar.gz,readline-$(READLINE_VERSION),readline)

ifneq ($(wildcard $(BUILD_WORK)/readline/.build_complete),)
readline:
	@echo "Using previously built readline."
else
readline: readline-setup ncurses
	cd $(BUILD_WORK)/readline && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		ac_cv_type_sig_atomic_t=no \
		LDFLAGS="$(CLFLAGS) $(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/readline \
		SHLIB_LIBS="-lncursesw"
		TERMCAP_LIB="-lncursesw"
	+$(MAKE) -C $(BUILD_WORK)/readline install \
		DESTDIR=$(BUILD_STAGE)/readline
	+$(MAKE) -C $(BUILD_WORK)/readline install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/readline/.build_complete
endif

readline-package: readline-stage
	# readline.mk Package Structure
	rm -rf $(BUILD_DIST)/libreadline{8,-dev}
	mkdir -p $(BUILD_DIST)/libreadline8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libreadline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share}

	# readline.mk Prep libreadline8
	cp -a $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/*.8.*dylib $(BUILD_DIST)/libreadline8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# readline.mk Prep libreadline-dev
	cp -a $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.8.*dylib) $(BUILD_DIST)/libreadline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/libreadline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# readline.mk Sign
	$(call SIGN,libreadline8,general.xml)

	# readline.mk Make .debs
	$(call PACK,libreadline8,DEB_READLINE_V)
	$(call PACK,libreadline-dev,DEB_READLINE_V)

	# readline.mk Build cleanup
	rm -rf $(BUILD_DIST)/libreadline{8,-dev}

.PHONY: readline readline-package
