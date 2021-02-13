ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += calc
CALC_VERSION := 2.12.7.2
DEB_CALC_V   ?= $(CALC_VERSION)

calc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://www.isthe.com/chongo/src/calc/calc-$(CALC_VERSION).tar.bz2
	$(call EXTRACT_TAR,calc-$(CALC_VERSION).tar.bz2,calc-$(CALC_VERSION),calc)
	$(SED) -i '/#include <stdio.h>/a #include <string.h>' $(BUILD_WORK)/calc/have_memmv.c
	$(SED) -i '/#include <stdio.h>/a #include <string.h>' $(BUILD_WORK)/calc/have_newstr.c
	$(SED) -i '/#include <stdio.h>/a #include <unistd.h>' $(BUILD_WORK)/calc/have_posscl.c

ifneq ($(wildcard $(BUILD_WORK)/calc/.build_complete),)
calc:
	@echo "Using previously built calc."
else
calc: calc-setup ncurses readline
	+$(MAKE) -C $(BUILD_WORK)/calc install \
		LCC=clang \
		CC=$(CC) \
		CFLAGS="$(CFLAGS) -DCALC_SRC -DCUSTOMHELPDIR=\"\\\"/usr/share/calc/custhelp\\\"\" -DHELPDIR=\"\\\"/usr/share/calc/help\\\"\" -DDEFAULTCALCPATH=\"\\\".:./cal:~/.cal:/usr/share/calc:/usr/share/calc/custom\\\"\" -I$(BUILD_WORK)" \
		LDFLAGS="$(LDFLAGS)" \
		target="Darwin" \
		BINDIR="/usr/bin" \
		LIBDIR="/usr/lib" \
		INCDIR="/usr/include" \
		CALC_SHAREDIR="/usr/share/calc" \
		CALCPAGER="pager" \
		USE_READLINE="-DUSE_READLINE" \
		READLINE_LIB="-lreadline" \
		READLINE_EXTRAS="-L$(BUILD_BASE)/usr/lib -lhistory -lncursesw" \
		BLD_TYPE="calc-static-only" \
		T="$(BUILD_STAGE)/calc" \
		-j1
	rm -rf $(BUILD_STAGE)/calc/usr/bin/{cscript,calc-static}
	touch $(BUILD_WORK)/calc/.build_complete
endif

calc-package: calc-stage
	# calc.mk Package Structure
	rm -rf $(BUILD_DIST)/calc{,-dev}
	mkdir -p $(BUILD_DIST)/calc{,-dev}/usr/lib
	
	# calc.mk Prep calc
	cp -a $(BUILD_STAGE)/calc/usr/{bin,share} $(BUILD_DIST)/calc/usr
	
	# calc.mk Prep calc-dev
	cp -a $(BUILD_STAGE)/calc/usr/include $(BUILD_DIST)/calc-dev/usr
	cp -a $(BUILD_STAGE)/calc/usr/lib/*.a $(BUILD_DIST)/calc-dev/usr/lib
	
	# calc.mk Sign
	$(call SIGN,calc,general.xml)
	
	# calc.mk Make .debs
	$(call PACK,calc,DEB_CALC_V)
	$(call PACK,calc-dev,DEB_CALC_V)
	
	# calc.mk Build cleanup
	rm -rf $(BUILD_DIST)/calc{,-dev}

.PHONY: calc calc-package
