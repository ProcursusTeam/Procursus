ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

# Update note: Please make sure new translated man pages are packaged correctly!

SUBPROJECTS        += util-linux
UTIL_LINUX_VERSION := 2.38
IONICE_TAG         := release-1
DEB_UTIL_LINUX_V   ?= $(UTIL_LINUX_VERSION)
MANPAGE_LANGS      := cs de es fr pt_BR sr uk

util-linux-setup: setup
	$(call GITHUB_ARCHIVE,util-linux,util-linux,$(UTIL_LINUX_VERSION),v$(UTIL_LINUX_VERSION))
	$(call GITHUB_ARCHIVE,DrHyde,ionice-MacOS,$(IONICE_TAG),$(IONICE_TAG))
	$(call EXTRACT_TAR,util-linux-$(UTIL_LINUX_VERSION).tar.gz,util-linux-$(UTIL_LINUX_VERSION),util-linux)
	$(call EXTRACT_TAR,ionice-MacOS-$(IONICE_TAG).tar.gz,ionice-MacOS-$(IONICE_TAG),util-linux/ionice-MacOS)
	sed -i 's|#include <sys/statfs.h>|#include <sys/mount.h>|g' $(BUILD_WORK)/util-linux/include/statfs_magic.h
	sed -i 's|#include <sys/vfs.h>|#include <sys/mount.h>|g' $(BUILD_WORK)/util-linux/lib/procfs.c
	sed -i 's|xasprintf(&progname, "mkfs.%s", fstype);|xasprintf(\&progname, "newfs_%s", fstype);|g' $(BUILD_WORK)/util-linux/disk-utils/mkfs.c
	sed -i '1s|^|#define DEFAULT_FSTYPE "hfs"\n|' $(BUILD_WORK)/util-linux/disk-utils/mkfs.c
	sed -i -e 's|/dev/sda|/dev/disk1|g' -e 's|"/dev/vda",||g' -e 's|"/dev/hda",||g' $(BUILD_WORK)/util-linux/disk-utils/cfdisk.c

ifneq ($(wildcard $(BUILD_WORK)/util-linux/.build_complete),)
util-linux:
	@echo "Using previously built util-linux."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
util-linux: util-linux-setup gettext openpam readline
else
util-linux: util-linux-setup gettext readline
endif
	cd $(BUILD_WORK)/util-linux && ./autogen.sh && \
		./configure -C \
			$(DEFAULT_CONFIGURE_FLAGS) \
			--enable-all-programs \
			--disable-ipcrm \
			--with-libintl-prefix='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)' \
			--disable-ipcs \
			--disable-schedutils  \
			--disable-use-tty-group \
			--with-util \
			--with-readline \
			--with-libmagic \
			--enable-nologin \
			--enable-poman \
			--enable-asciidoc \
			--disable-pylibmount \
			--disable-libmount
	+$(MAKE) -C $(BUILD_WORK)/util-linux \
		NCURSES_LIBS=-lncursesw;
	+$(MAKE) -C $(BUILD_WORK)/util-linux install \
		DESTDIR=$(BUILD_STAGE)/util-linux
	$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_WORK)/util-linux/ionice-MacOS/ionice.c -o $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ionice
	pod2man -r "IONICE(1)" -c "ionice documentation" $(BUILD_WORK)/util-linux/ionice-MacOS/ionice.pod $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/ionice.1
	for fs in minix cramfs bfs; do \
		mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)/sbin/{mkfs.$${fs},newfs_$${fs}}; \
		mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/{mkfs.$${fs},newfs_$${fs}}.8; \
		mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/{mkfs.,newfs_}$${fs}; \
		sed -i -e 's/_mkfs.'$${fs}'_module()/_newfs_'$${fs}'_module()/' -e 's/complete -F _mkfs.'$${fs}'_module mkfs.'$${fs}'/complete -F _newfs_'$${fs}'_module newfs_'$${fs}'/' $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/newfs_$${fs}; \
	done
	mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)/sbin/{mkfs,newfs};
	mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/{mkfs,newfs}.8;
	mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/{mkfs,newfs};
	sed -i -e 's/_mkfs_module()/_newfs_module()/' -e 's/complete -F _mkfs_module mkfs/complete -F _newfs_module newfs/' $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/newfs
	for fs in cramfs minix; do \
		mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)/sbin/fsck{.,_}$${fs}; \
		mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/fsck{.,_}$${fs}.8; \
		mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/fsck{.,_}$${fs}; \
		sed -i -e 's/_fsck.'$${fs}'_module()/_fsck_'$${fs}'_module()/' -e 's/complete -F _fsck.'$${fs}'_module fsck.'$${fs}'/complete -F _fsck_'$${fs}'_module fsck_'$${fs}'/' $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/fsck_$${fs}; \
	done
	mv $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/uuid/{,ul_}uuid.h
	$(call AFTER_BUILD,copy)
endif

util-linux-package: util-linux-stage
	# util-linux.mk Package Structure
	rm -rf $(BUILD_DIST)/{util-linux,util-linux-locales,fdisk,bsdutils,libfdisk1,libfdisk-dev,libblkid1,libblkid-dev,libsmartcols1,libsmartcols-dev,libuuid1,uuid-dev,uuid-runtime}
	mkdir -p $(BUILD_DIST)/{util-linux,fdisk,bsdutils,libfdisk1,libfdisk-dev,libblkid1,libblkid-dev,libsmartcols1,libsmartcols-dev,libuuid1,uuid-dev,uuid-runtime}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{$(shell echo ",$$(echo '$(MANPAGE_LANGS)' | sed 's/ /,/g')")}/man{1,3,5,8}
	mkdir -p $(BUILD_DIST)/util-linux-locales/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/{util-linux,bsdutils,uuid-runtime}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{man/man1,bash-completion/completions}}
	mkdir -p $(BUILD_DIST)/{util-linux,fdisk}/$(MEMO_PREFIX)/{sbin,$(MEMO_SUB_PREFIX)/share/{bash-completion/completions,man/man8}}
	mkdir -p $(BUILD_DIST)/{util-linux,fdisk,bsdutils,libfdisk1,libfdisk-dev,libblkid1,libblkid-dev,libsmartcols1,libsmartcols-dev,libuuid1,uuid-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{uuid-dev,libblkid-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3
	mkdir -p $(BUILD_DIST)/lib{fdisk,blkid,smartcols,uuid}1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/{uuid-dev,libfdisk-dev,libblkid-dev,libsmartcols-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include}

	# util-linux.mk Prep util-linux
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)/sbin/{newfs,newfs_bfs,newfs_cramfs,newfs_minix,fsck_cramfs,fsck_minix,mkswap,swaplabel,blkid,wipefs} $(BUILD_DIST)/util-linux/$(MEMO_PREFIX)/sbin
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{flock,ionice,mcookie,setsid,namei,isosize,hardlink,line,pg} $(BUILD_DIST)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	-for lang in '' $(MANPAGE_LANGS); do \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/{flock,mcookie,setsid,namei,hardlink,line,pg}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1; \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man8/{newfs,newfs_bfs,newfs_cramfs,newfs_minix,fsck_cramfs,fsck_minix,mkswap,swaplabel,blkid,isosize,wipefs}.8$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man8; \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man5/terminal-colors.d.5$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man5; \
	done
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/ionice.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/{newfs,newfs_bfs,newfs_cramfs,newfs_minix,fsck_cramfs,fsck_minix,mkswap,swaplabel,blkid,isosize,wipefs,flock,mcookie,setsid,namei,hardlink,pg} $(BUILD_DIST)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions

	# util-linux.mk Prep util-linux-locales
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/util-linux-locales/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# util-linux.mk Prep fdisk
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)/sbin/{c,s}fdisk $(BUILD_DIST)/fdisk/$(MEMO_PREFIX)/sbin
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/{c,s}fdisk $(BUILD_DIST)/fdisk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/
	-for lang in '' $(MANPAGE_LANGS); do \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man8/{c,s}fdisk.8$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/fdisk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man8; \
	done

	# util-linux.mk Prep libblkid-dev
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libblkid.{dylib,a} $(BUILD_DIST)/libblkid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/blkid.pc $(BUILD_DIST)/libblkid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/blkid $(BUILD_DIST)/libblkid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	-for lang in '' $(MANPAGE_LANGS); do \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man3/libblkid.3$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/libblkid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man3; \
	done

	# util-linux.mk Prep libblkid1
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libblkid.1.dylib $(BUILD_DIST)/libblkid1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# util-linux.mk Prep libsmartcols-dev
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsmartcols.{dylib,a} $(BUILD_DIST)/libsmartcols-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/smartcols.pc $(BUILD_DIST)/libsmartcols-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libsmartcols $(BUILD_DIST)/libsmartcols-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# util-linux.mk Prep libsmartcols1
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsmartcols.1.dylib $(BUILD_DIST)/libsmartcols1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# util-linux.mk Prep libuuid1
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuuid.1.dylib $(BUILD_DIST)/libuuid1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# util-linux.mk Prep uuid-dev
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuuid.{dylib,a} $(BUILD_DIST)/uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/uuid.pc $(BUILD_DIST)/uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/uuid $(BUILD_DIST)/uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	-for lang in '' $(MANPAGE_LANGS); do \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man3/uuid*.3$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/uuid-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man3; \
	done

	# util-linux.mk Prep uuid-runtime
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uuid{gen,parse} $(BUILD_DIST)/uuid-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/uuid{gen,parse} $(BUILD_DIST)/uuid-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/
	-for lang in '' $(MANPAGE_LANGS); do \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/uuid{gen,parse}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/uuid-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1; \
	done

	# util-linux.mk Prep bsdutils
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/scriptreplay $(BUILD_DIST)/bsdutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/scriptreplay  $(BUILD_DIST)/bsdutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/
	-for lang in '' $(MANPAGE_LANGS); do \
		cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1/scriptreplay.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/bsdutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man1; \
	done

	# util-linux.mk Prep libfdisk1
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfdisk.1.dylib $(BUILD_DIST)/libfdisk1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# util-linux.mk Prep libfdisk-dev
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfdisk.{dylib,a} $(BUILD_DIST)/libfdisk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/fdisk.pc $(BUILD_DIST)/libfdisk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/util-linux/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libfdisk $(BUILD_DIST)/libfdisk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# Remove empty man directories
	for pkg in util-linux fdisk bsdutils libfdisk1 libfdisk-dev libblkid1 libblkid-dev libsmartcols1 libsmartcols-dev libuuid1 uuid-dev uuid-runtime; do \
		if find $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f | grep . > /dev/null; then \
			for section in 1 3 5 8; do \
				if find $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man$${section} -type f | grep . > /dev/null; then \
					for lang in $(MANPAGE_LANGS); do \
						if ! find $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man$${section} -type f | grep . > /dev/null; then \
							rm -rf $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}/man$${section}; \
						fi; \
						if ! find $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang} -type f | grep . > /dev/null; then \
							rm -rf $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/$${lang}; \
						fi; \
					done; \
				else \
					rm -rf $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{$(shell echo ",$$(echo '$(MANPAGE_LANGS)' | sed 's/ /,/g')")}/man$${section}; \
				fi; \
			done; \
		else \
			rm -rf $(BUILD_DIST)/$${pkg}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man; \
		fi; \
	done

	# util-linux.mk Sign
	$(call SIGN,util-linux,dd.xml)
	$(call SIGN,fdisk,dd.xml)
	$(call SIGN,bsdutils,general.xml)
	$(call SIGN,libfdisk1,general.xml)
	$(call SIGN,libsmartcols1,general.xml)
	$(call SIGN,libuuid1,general.xml)
	$(call SIGN,uuid-runtime,general.xml)

	# util-linux.mk Make .debs
	$(call PACK,util-linux,DEB_UTIL_LINUX_V)
	$(call PACK,util-linux-locales,DEB_UTIL_LINUX_V)
	$(call PACK,fdisk,DEB_UTIL_LINUX_V)
	$(call PACK,bsdutils,DEB_UTIL_LINUX_V)
	$(call PACK,libfdisk1,DEB_UTIL_LINUX_V)
	$(call PACK,libfdisk-dev,DEB_UTIL_LINUX_V)
	$(call PACK,libblkid1,DEB_UTIL_LINUX_V)
	$(call PACK,libblkid-dev,DEB_UTIL_LINUX_V)
	$(call PACK,libsmartcols1,DEB_UTIL_LINUX_V)
	$(call PACK,libsmartcols-dev,DEB_UTIL_LINUX_V)
	$(call PACK,libuuid1,DEB_UTIL_LINUX_V)
	$(call PACK,uuid-dev,DEB_UTIL_LINUX_V)
	$(call PACK,uuid-runtime,DEB_UTIL_LINUX_V)

	# util-linux.mk Build cleanup
	rm -rf $(BUILD_DIST)/{util-linux,util-linux-locales,fdisk,bsdutils,libfdisk1,libfdisk-dev,libblkid1,libblkid-dev,libsmartcols1,libsmartcols-dev,libuuid1,uuid-dev,uuid-runtime}

.PHONY: util-linux util-linux-package
