ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += tmux
TMUX_VERSION   := 3.1c
DEB_TMUX_V     ?= $(TMUX_VERSION)-1

tmux-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tmux/tmux/releases/download/$(TMUX_VERSION)/tmux-$(TMUX_VERSION).tar.gz
	$(call EXTRACT_TAR,tmux-$(TMUX_VERSION).tar.gz,tmux-$(TMUX_VERSION),tmux)

ifneq ($(wildcard $(BUILD_WORK)/tmux/.build_complete),)
tmux:
	@echo "Using previously built tmux."
else
tmux: tmux-setup ncurses libevent libutf8proc
	cd $(BUILD_WORK)/tmux && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-utf8proc \
		ac_cv_func_strtonum=no \
		LIBNCURSES_LIBS="-lncursesw" \
		LIBNCURSES_CFLAGS="-I$(BUILD_BASE)/usr/include/ncursesw"
	+$(MAKE) -C $(BUILD_WORK)/tmux install \
		DESTDIR=$(BUILD_STAGE)/tmux
	touch $(BUILD_WORK)/tmux/.build_complete
endif

tmux-package: tmux-stage
	# tmux.mk Package Structure
	rm -rf $(BUILD_DIST)/tmux
	mkdir -p $(BUILD_DIST)/tmux
	
	# tmux.mk Prep tmux
	cp -a $(BUILD_STAGE)/tmux/usr $(BUILD_DIST)/tmux
	
	# tmux.mk Sign
	$(call SIGN,tmux,general.xml)
	
	# tmux.mk Make .debs
	$(call PACK,tmux,DEB_TMUX_V)
	
	# tmux.mk Build cleanup
	rm -rf $(BUILD_DIST)/tmux

.PHONY: tmux tmux-package
