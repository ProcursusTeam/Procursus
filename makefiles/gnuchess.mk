ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += gnuchess
GNUCHESS_VERSION := 6.2.7
DEB_GNUCHESS_V   ?= $(GNUCHESS_VERSION)-2

gnuchess-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mirror.its.dal.ca/gnu/chess/gnuchess-$(GNUCHESS_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,gnuchess-$(GNUCHESS_VERSION).tar.gz)
	$(call EXTRACT_TAR,gnuchess-$(GNUCHESS_VERSION).tar.gz,gnuchess-$(GNUCHESS_VERSION),gnuchess)

ifneq ($(wildcard $(BUILD_WORK)/gnuchess/.build_complete),)
gnuchess:
	@echo "Using previously built gnuchess."
else
gnuchess: gnuchess-setup ncurses readline gettext
	cd $(BUILD_WORK)/gnuchess && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/gnuchess \
		LIBS="-lreadline -lncursesw"
	+$(MAKE) -C $(BUILD_WORK)/gnuchess install \
		DESTDIR=$(BUILD_STAGE)/gnuchess
	touch $(BUILD_WORK)/gnuchess/.build_complete
endif

gnuchess-package: gnuchess-stage
	# gnuchess.mk Package Structure
	rm -rf $(BUILD_DIST)/gnuchess

	# gnuchess.mk Prep gnuchess
	cp -a $(BUILD_STAGE)/gnuchess $(BUILD_DIST)

	# gnuchess.mk Sign
	$(call SIGN,gnuchess,general.xml)

	# gnuchess.mk Make .debs
	$(call PACK,gnuchess,DEB_GNUCHESS_V)

	# gnuchess.mk Build cleanup
	rm -rf $(BUILD_DIST)/gnuchess

.PHONY: gnuchess gnuchess-package
