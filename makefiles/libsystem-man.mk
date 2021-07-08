ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS           += libsystem-man
LIBSYSTEM-MAN_VERSION := 1.1
DEB_LIBSYSTEM-MAN_V   ?= $(LIBSYSTEM-MAN_VERSION)

libsystem-man-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://sudhip.com/files/darwin-manpages/man{2,3,4,8}.tar.gz{,.sig}

	$(call PGP_VERIFY,man2.tar.gz)
	$(call PGP_VERIFY,man3.tar.gz)
	$(call PGP_VERIFY,man4.tar.gz)

	$(call EXTRACT_TAR,man2.tar.gz,man2,libsystem-man/man2)
	$(call EXTRACT_TAR,man3.tar.gz,man3,libsystem-man/man3)
	$(call EXTRACT_TAR,man4.tar.gz,man4,libsystem-man/man4)

ifneq ($(wildcard $(BUILD_WORK)/libsystem-man/.build_complete),)
libsystem-man:
	@echo "Using previously built libsystem-man."
else
libsystem-man: libsystem-man-setup
	mkdir -p $(BUILD_STAGE)/libsystem-man/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	find $(BUILD_WORK)/libsystem-man -type l -exec sh -c 'd=$$(readlink {}); unlink {}; ln -s "$$d.zst" {}' \;
	$(CP) -a $(BUILD_WORK)/libsystem-man $(BUILD_STAGE)/libsystem-man/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	touch $(BUILD_WORK)/libsystem-man/.build_complete
endif

libsystem-man-package: libsystem-man-stage
	# libsystem-man.mk Package Structure
	rm -rf $(BUILD_DIST)/libsystem-man

	# libsystem-man.mk Prep libsystem-man
	cp -a $(BUILD_STAGE)/libsystem-man $(BUILD_DIST)

	# libsystem-man.mk Make .debs
	$(call PACK,libsystem-man,DEB_LIBSYSTEM-MAN_V)

	# libsystem-man.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsystem-man

.PHONY: libsystem-man libsystem-man-package

endif
