ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS    += readline
READLINE_VERSION := 8.0
DEB_READLINE_V   ?= $(READLINE_VERSION).$(READLINE_SUB_V)-1

readline-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/readline/readline-$(READLINE_VERSION).tar.gz{,.sig} \
		https://ftpmirror.gnu.org/readline/readline-$(READLINE_VERSION)-patches/readline80-00{1..4}{,.sig}
	$(call PGP_VERIFY,readline-$(READLINE_VERSION).tar.gz)
	$(call PGP_VERIFY,readline80-001)
	$(call PGP_VERIFY,readline80-002)
	$(call PGP_VERIFY,readline80-003)
	$(call PGP_VERIFY,readline80-004)
	$(call EXTRACT_TAR,readline-$(READLINE_VERSION).tar.gz,readline-$(READLINE_VERSION),readline)
	mkdir -p $(BUILD_PATCH)/readline-$(READLINE_VERSION)
	find $(BUILD_SOURCE) -name 'readline80*' -not -name '*.sig' -exec cp '{}' $(BUILD_PATCH)/readline-$(READLINE_VERSION)/ \;
	$(call DO_PATCH,readline-$(READLINE_VERSION),readline,-p0)

ifneq ($(wildcard $(BUILD_WORK)/readline/.build_complete),)
readline:
	@echo "Using previously built readline."
else
readline: readline-setup ncurses
	cd $(BUILD_WORK)/readline && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
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

readline-package: READLINE_SUB_V=$(shell find $(BUILD_PATCH)/readline-$(READLINE_VERSION) -type f | $(WC) -l)
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
