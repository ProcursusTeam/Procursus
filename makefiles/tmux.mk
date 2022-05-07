ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += tmux
TMUX_VERSION   := 3.2a
DEB_TMUX_V     ?= $(TMUX_VERSION)

tmux-setup: setup
	$(call GITHUB_ARCHIVE,tmux,tmux,$(TMUX_VERSION),$(TMUX_VERSION))
	$(call EXTRACT_TAR,tmux-$(TMUX_VERSION).tar.gz,tmux-$(TMUX_VERSION),tmux)
	$(call DO_PATCH,tmux,tmux,-p1)

ifneq ($(wildcard $(BUILD_WORK)/tmux/.build_complete),)
tmux:
	@echo "Using previously built tmux."
else
tmux: tmux-setup ncurses libevent libutf8proc
	cd $(BUILD_WORK)/tmux && autoreconf -fi
	cd $(BUILD_WORK)/tmux && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-static \
		--enable-utf8proc \
		LIBNCURSES_LIBS="-lncursesw" \
		LIBNCURSES_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ncursesw"
	+$(MAKE) -C $(BUILD_WORK)/tmux install \
		DESTDIR=$(BUILD_STAGE)/tmux
	$(call AFTER_BUILD)
endif

tmux-package: tmux-stage
	# tmux.mk Package Structure
	rm -rf $(BUILD_DIST)/tmux
	mkdir -p $(BUILD_DIST)/tmux

	# tmux.mk Prep tmux
	cp -a $(BUILD_STAGE)/tmux $(BUILD_DIST)

	# tmux.mk Sign
	$(call SIGN,tmux,general.xml)

	# tmux.mk Make .debs
	$(call PACK,tmux,DEB_TMUX_V)

	# tmux.mk Build cleanup
	rm -rf $(BUILD_DIST)/tmux

.PHONY: tmux tmux-package
