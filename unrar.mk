ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

UNRAR_VERSION := 5.9.2
DEB_UNRAR_V   ?= $(UNRAR_VERSION)

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

ifneq ($(wildcard $(BUILD_WORK)/unrar/.build_complete),)
unrar:
	@echo "Using previously built unrar."
else
unrar: setup
	$(SED) -i 's/libunrar.so/libunrar.dylib/g' $(BUILD_WORK)/unrar/makefile
	$(MAKE) -C $(BUILD_WORK)/unrar \
		CXX="$(CXX)" \
		STRIP=$(STRIP) \
		CPPFLAGS="$(CFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/unrar clean ; \
	$(MAKE) -C $(BUILD_WORK)/unrar lib \
		CXX="$(CXX)" \
		AR="$(AR)" \
		STRIP=$(STRIP) \
		CPPFLAGS="$(CFLAGS)"
	mkdir -p $(BUILD_STAGE)/unrar/usr/{bin,lib}
	$(MAKE) -C $(BUILD_WORK)/unrar install-lib \
		DESTDIR=$(BUILD_BASE)/usr
	$(MAKE) -C $(BUILD_WORK)/unrar install-lib \
		DESTDIR=$(BUILD_STAGE)/unrar/usr
	$(MAKE) -C $(BUILD_WORK)/unrar install-unrar \
		DESTDIR=$(BUILD_STAGE)/unrar/usr
	touch $(BUILD_WORK)/unrar/.build_complete
endif

unrar-package: unrar-stage
	# unrar.mk Package Structure
	rm -rf $(BUILD_DIST)/unrar
	mkdir -p $(BUILD_DIST)/unrar/bin
	
	# unrar.mk Prep unrar
	$(FAKEROOT) cp -a $(BUILD_STAGE)/unrar/usr $(BUILD_DIST)/unrar
	
	# unrar.mk Sign
	$(call SIGN,unrar,general.xml)
	
	# unrar.mk Make .debs
	$(call PACK,unrar,DEB_UNRAR_V)
	
	# unrar.mk Build cleanup
	rm -rf $(BUILD_DIST)/unrar

.PHONY: unrar unrar-package
