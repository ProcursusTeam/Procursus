ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq ($(MEMO_TARGET),darwin-\*)
STRAPPROJECTS    += readline
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS      += readline
endif # ($(MEMO_TARGET),darwin-\*)
READLINE_VERSION := 8.1
READLINE_PATCH   := 2
DEB_READLINE_V   ?= $(READLINE_VERSION).$(READLINE_PATCH)

readline-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftp.gnu.org/gnu/readline/readline-$(READLINE_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,readline-$(READLINE_VERSION).tar.gz)
	$(call EXTRACT_TAR,readline-$(READLINE_VERSION).tar.gz,readline-$(READLINE_VERSION),readline)
	$(call DO_PATCH,readline,readline,-p0)
	sed -i 's|/etc/inputrc|$(MEMO_PREFIX)/etc/inputrc|' $(BUILD_WORK)/readline/rlconf.h

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
		SHLIB_LIBS="-lncursesw" \
		TERMCAP_LIB="-lncursesw"
	+$(MAKE) -C $(BUILD_WORK)/readline install \
		DESTDIR=$(BUILD_STAGE)/readline
	# I blame Debian for this mess
	awk '/^#if defined \(HAVE_CONFIG_H\)/, /^#endif/ \
		{if ($$0 == "#else") print "#include <string.h>"; next} {print}' \
		$(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline/chardefs.h \
	> $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline/chardefs.h.new
	if diff -u $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline/chardefs.h \
		$(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline/chardefs.h.new; \
	then \
		rm -f $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline/chardefs.h.new; \
	else \
		mv -f $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline/chardefs.h.new \
			$(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline/chardefs.h; \
        fi
	mv $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/readline.3 $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/readline.3readline
	mv $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/history.3 $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3/history.3readline
	rm -rf $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/readline/*
	cp -a $(BUILD_WORK)/readline/examples $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/readline/
	cp -a $(BUILD_WORK)/readline/examples/Inputrc $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/readline/examples/
	cp -a $(BUILD_MISC)/readline/inputrc.arrows $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/readline/
	cp -a $(BUILD_MISC)/readline/inputrc $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/readline/
	$(LN_S) libreadline.8.dylib $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libreadline.dylib
	$(LN_S) libhistory.8.dylib $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libhistory.dylib
	$(call AFTER_BUILD,copy)
endif

readline-package: readline-stage
	# readline.mk Package Structure
	mkdir -p $(BUILD_DIST)/libreadline{8,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# readline.mk Prep libreadline8
	cp -a $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/*.8.*dylib $(BUILD_DIST)/libreadline8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# readline.mk Prep libreadline-dev
	cp -a $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib{readline,history}.dylib $(BUILD_DIST)/libreadline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libreadline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/readline/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libreadline-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# readline.mk Sign
	$(call SIGN,libreadline8,general.xml)

	# readline.mk Make .debs
	$(call PACK,libreadline8,DEB_READLINE_V)
	$(call PACK,libreadline-dev,DEB_READLINE_V)

	# readline.mk Build cleanup
	rm -rf $(BUILD_DIST)/libreadline{8,-dev}

.PHONY: readline readline-package
