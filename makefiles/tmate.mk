ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += tmate
TMATE_VERSION := 2.4.0
DEB_TMATE_V   := $(TMATE_VERSION)

tmate-setup: setup
	$(call GITHUB_ARCHIVE,tmate-io,tmate,$(TMATE_VERSION),$(TMATE_VERSION))
	$(call EXTRACT_TAR,tmate-$(TMATE_VERSION).tar.gz,tmate-$(TMATE_VERSION),tmate)
	echo '' > $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define u_char unsigned char' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define _U_CHAR' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define u_long unsigned long' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define u_short unsigned short' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define _U_INT' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define u_int unsigned int' >> $(BUILD_WORK)/tmate/my_udefs.h

	echo '#define SIGWINCH 28' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define IMAXBEL 0020000' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define ECHOCTL 0x00000040' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define ECHOKE 0x00000001' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define SOCK_MAXADDRLEN 255' >> $(BUILD_WORK)/tmate/my_udefs.h

	echo 'typedef void *rusage_info_t;' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo '#define TTY_NAME_MAX 32' >> $(BUILD_WORK)/tmate/my_udefs.h
	echo "" > $(BUILD_WORK)/tmate/compat/forkpty-darwin.c
	sed -i 's/unused int/int/g' $(BUILD_WORK)/tmate/compat/setenv.c


ifneq ($(wildcard $(BUILD_WORK)/tmate/.build_complete),)
tmate:
	@echo "Using previously built tmate."
else
tmate: tmate-setup libevent ncurses msgpack libssh
	cd $(BUILD_WORK)/tmate && ./autogen.sh
	cd $(BUILD_WORK)/tmate && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-static \
		ac_cv_func_strlcpy=yes \
		ac_cv_func_strlcat=yes \
		CFLAGS="-include $(BUILD_WORK)/tmate/my_udefs.h" \
		LIBEVENT_LIBS="-levent" \
		LIBEVENT_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/usr/include/" \
		MSGPACK_LIBS="-lmsgpackc" \
		MSGPACK_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/usr/include/msgpack" \
		LIBSSH_LIBS="-lssh" \
		LIBSSH_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/usr/include/libssh"
	+$(MAKE) -C $(BUILD_WORK)/tmate install \
		DESTDIR="$(BUILD_STAGE)/tmate"
	$(call AFTER_BUILD)
endif
tmate-package: tmate-stage
	# tmate.mk Package Structure
	rm -rf $(BUILD_DIST)/tmate

	# tmate.mk Prep tmate
	cp -a $(BUILD_STAGE)/tmate $(BUILD_DIST)

	# tmate.mk Sign
	$(call SIGN,tmate,general.xml)

	# tmate.mk Make .debs
	$(call PACK,tmate,DEB_TMATE_V)

	# tmate.mk Build cleanup
	rm -rf $(BUILD_DIST)/tmate

.PHONY: tmate tmate-package
