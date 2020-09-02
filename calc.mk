ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += calc
CALC_VERSION := 2.12.7.1
DEB_CALC_V   ?= $(CALC_VERSION)

calc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://www.isthe.com/chongo/src/calc/calc-$(CALC_VERSION).tar.bz2
	$(call EXTRACT_TAR,calc-$(CALC_VERSION).tar.bz2,calc-$(CALC_VERSION),calc)
	$(call DO_PATCH,calc,calc,-p1)

ifneq ($(wildcard $(BUILD_WORK)/calc/.build_complete),)
calc:
	@echo "Using previously built calc."
else
calc: calc-setup ncurses readline
	+unset CC CFLAGS CXXFLAGS CPPFLAGS LDFLAGS RANLIB && $(MAKE) -C $(BUILD_WORK)/calc install \
		DEFAULT_LIB_INSTALL_PATH="$(BUILD_WORK)/calc:$(BUILD_BASE)/usr/lib:/lib:/usr/lib:/usr/local/lib" \
		LCC=clang \
		CC=$(CC) \
		RANLIB="$(RANLIB)" \
		target="Darwin" \
		BINDIR="/usr/bin" \
		LIBDIR="/usr/lib" \
		CALC_SHAREDIR="/usr/share/calc" \
		CUSTOMCALDIR="/usr/share/calc/custom" \
		HELPDIR="/usr/share/calc/help" \
		CFLAGS="$(CFLAGS) -DCALC_SRC -I$(BUILD_WORK)" \
		LDFLAGS="$(LDFLAGS) -I$(BUILD_WORK)" \
		USE_READLINE="-DUSE_READLINE" \
		READLINE_LIB="-lreadline" \
		READLINE_EXTRAS="-L$(BUILD_BASE)/usr/lib -lhistory -lncursesw" \
		BLD_TYPE="calc-static-only" \
		T=$(BUILD_STAGE)/calc \
		-j1
	rm -rf $(BUILD_STAGE)/calc/usr/bin/{cscript,calc-static}
	touch $(BUILD_WORK)/calc/.build_complete
endif

calc-package: calc-stage
	# calc.mk Package Structure
	rm -rf $(BUILD_DIST)/calc{,-dev}
	mkdir -p $(BUILD_DIST)/calc{,-dev}/usr
	
	# calc.mk Prep calc
	cp -a $(BUILD_STAGE)/calc/usr/{bin,share} $(BUILD_DIST)/calc/usr
	
	# calc.mk Prep calc-dev
	cp -a $(BUILD_STAGE)/calc/usr/include $(BUILD_DIST)/calc-dev/usr
	
	# calc.mk Sign
	$(call SIGN,calc,general.xml)
	
	# calc.mk Make .debs
	$(call PACK,calc,DEB_CALC_V)
	$(call PACK,calc-dev,DEB_CALC_V)
	
	# calc.mk Build cleanup
	rm -rf $(BUILD_DIST)/calc{,-dev}

.PHONY: calc calc-package
