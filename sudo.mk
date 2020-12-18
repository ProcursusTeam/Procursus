ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += sudo
SUDO_VERSION  := 1.9.4p1
DEB_SUDO_V    ?= $(SUDO_VERSION)

sudo-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.sudo.ws/dist/sudo-$(SUDO_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,sudo-$(SUDO_VERSION).tar.gz)
	$(call EXTRACT_TAR,sudo-$(SUDO_VERSION).tar.gz,sudo-$(SUDO_VERSION),sudo)

ifneq ($(wildcard $(BUILD_WORK)/sudo/.build_complete),)
sudo:
	@echo "Using previously built sudo."
else
sudo: sudo-setup gettext libxcrypt
		$(SED) -i '/#include "sudo_plugin_int.h"/a #include <dlfcn.h>\
\/* Set platform binary flag *\/\
#define FLAG_PLATFORMIZE (1 << 1)\
\
void patch_setuidandplatformize() {\
\	void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);\
\	if (!handle) return;\
\
\	// Reset errors\
\	dlerror();\
\
\	typedef void (*fix_setuid_prt_t)(pid_t pid);\
\	fix_setuid_prt_t setuidptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");\
\
\	typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);\
\	fix_entitle_prt_t entitleptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");\
\
\	setuidptr(getpid());\
\
\	seteuid(0);\
\
\	const char *dlsym_error = dlerror();\
\	if (dlsym_error) {\
\	\	return;\
\	}\
\
\	entitleptr(getpid(), FLAG_PLATFORMIZE);\
}' $(BUILD_WORK)/sudo/src/sudo.c
	$(SED) -i '/int nargc/i \	patch_setuidandplatformize();' $(BUILD_WORK)/sudo/src/sudo.c
	$(SED) -i 's/errno == ENOEXEC)/(errno == ENOEXEC || errno == EPERM))/g' $(BUILD_WORK)/sudo/src/exec_common.c
	$(SED) -i 's/+ 2/+ 4/g' $(BUILD_WORK)/sudo/src/exec_common.c
	$(SED) -i 's/nargv\[1\] = (char \*)path;/nargv\[1\] = "-c";/g' $(BUILD_WORK)/sudo/src/exec_common.c
	$(SED) -i '/nargv\[1\]/a \	\	nargv[2] = "exec \\"$$0\\" \\"$$@\\"";\
\	\	nargv[3] = (char *)path;' $(BUILD_WORK)/sudo/src/exec_common.c
	$(SED) -i '/%sudo/a \\n## Uncomment to allow members of group mobile to execute any command\n%mobile	ALL=(ALL) ALL' $(BUILD_WORK)/sudo/plugins/sudoers/sudoers.in

	cd $(BUILD_WORK)/sudo && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-pam \
		--enable-static-sudoers \
		--with-all-insults \
		--with-env-editor \
		--with-editor=/usr/bin/editor \
		--with-timeout=15 \
		--with-password-timeout=0 \
		--with-passprompt="[sudo] password for %p: " \
		sudo_cv___func__=yes \
		ac_cv_search_crypt="-lcrypt"
	+$(MAKE) -C $(BUILD_WORK)/sudo
	+$(MAKE) -C $(BUILD_WORK)/sudo install \
		DESTDIR=$(BUILD_STAGE)/sudo \
		INSTALL_OWNER=''
	touch $(BUILD_WORK)/sudo/.build_complete
endif

sudo-package: sudo-stage
	# sudo.mk Package Structure
	rm -rf $(BUILD_DIST)/sudo
	
	# sudo.mk Prep sudo
	cp -a $(BUILD_STAGE)/sudo $(BUILD_DIST)
	
	# sudo.mk Sign
	$(call SIGN,sudo,general.xml)

	# sudo.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/sudo/usr/bin/sudo
	
	# sudo.mk Make .debs
	$(call PACK,sudo,DEB_SUDO_V)
	
	# sudo.mk Build cleanup
	rm -rf $(BUILD_DIST)/sudo

.PHONY: sudo sudo-package
