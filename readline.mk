ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS    += readline
DOWNLOAD         += https://ftp.gnu.org/gnu/readline/readline-$(READLINE_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/readline/readline-$(READLINE_VERSION)-patches/readline80-00{1..4}{,.sig}
READLINE_VERSION := 8.0
DEB_READLINE_V   ?= $(READLINE_VERSION).$(READLINE_SUB_V)

readline-setup: setup
	$(call PGP_VERIFY,readline-$(READLINE_VERSION).tar.gz)
	$(call PGP_VERIFY,readline80-001)
	$(call PGP_VERIFY,readline80-002)
	$(call PGP_VERIFY,readline80-003)
	$(call PGP_VERIFY,readline80-004)
	$(call EXTRACT_TAR,readline-$(READLINE_VERSION).tar.gz,readline-$(READLINE_VERSION),readline)
	mkdir -p $(BUILD_WORK)/readline-$(READLINE_VERSION)-patches
	find $(BUILD_SOURCE) -name 'readline80*' -not -name '*.sig' -exec cp '{}' $(BUILD_WORK)/readline-$(READLINE_VERSION)-patches/ \;
	$(call DO_PATCH,readline-$(READLINE_VERSION),readline,-p0)

ifneq ($(wildcard $(BUILD_WORK)/readline/.build_complete),)
readline:
	@echo "Using previously built readline."
else
readline: readline-setup ncurses
	cd $(BUILD_WORK)/readline && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
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

readline-package: READLINE_SUB_V=$(shell find $(BUILD_WORK)/readline-$(READLINE_VERSION)-patches -type f | $(WC) -l)
readline-package: readline-stage
	# readline.mk Package Structure
	rm -rf $(BUILD_DIST)/readline
	mkdir -p $(BUILD_DIST)/readline
	
	# readline.mk Prep readline
	cp -a $(BUILD_STAGE)/readline/usr $(BUILD_DIST)/readline
	
	# readline.mk Sign
	$(call SIGN,readline,general.xml)
	
	# readline.mk Make .debs
	$(call PACK,readline,DEB_READLINE_V)
	
	# readline.mk Build cleanup
	rm -rf $(BUILD_DIST)/readline

.PHONY: readline readline-package
