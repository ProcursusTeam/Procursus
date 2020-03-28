ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

READLINE_VERSION := 8.0
READLINE_SUB_V   := $(shell find $(BUILD_SOURCE) -name 'readline80*' -not -name '*.sig' | wc -l)
DEB_READLINE_V   ?= $(READLINE_VERSION).$(READLINE_SUB_V)

ifneq ($(wildcard $(BUILD_WORK)/readline/.build_complete),)
readline:
	@echo "Using previously built readline."
else
readline: setup ncurses
	cd $(BUILD_WORK)/readline && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		ac_cv_type_sig_atomic_t=no \
		LDFLAGS="$(CLFLAGS) $(LDFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/readline \
		SHLIB_LIBS="-lncursesw"
		TERMCAP_LIB="-lncursesw"
	$(MAKE) -C $(BUILD_WORK)/readline install \
		DESTDIR=$(BUILD_STAGE)/readline
	$(MAKE) -C $(BUILD_WORK)/readline install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/readline/.build_complete
endif

readline-package: readline-stage
	# readline.mk Package Structure
	rm -rf $(BUILD_DIST)/readline
	mkdir -p $(BUILD_DIST)/readline
	
	# readline.mk Prep readline
	$(FAKEROOT) cp -a $(BUILD_STAGE)/readline/usr $(BUILD_DIST)/readline
	
	# readline.mk Sign
	$(call SIGN,readline,general.xml)
	
	# readline.mk Make .debs
	$(call PACK,readline,DEB_READLINE_V)
	
	# readline.mk Build cleanup
	rm -rf $(BUILD_DIST)/readline

.PHONY: readline readline-package
