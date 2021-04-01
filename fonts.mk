ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += Fonts
FONTS_VERSION := 1.0
font-adobe-75dpi := 1.0.3
font-adobe-100dpi := 1.0.3
font-adobe-utopia-75dpi := 1.0.4
font-adobe-utopia-100dpi := 1.0.4
font-adobe-utopia-type1 := 1.0.4
font-arabic-misc := 1.0.3
font-bh-75dpi := 1.0.3
font-bh-100dpi := 1.0.3
font-bh-lucidatypewriter-75dpi := 1.0.3
font-bh-lucidatypewriter-100dpi := 1.0.3
font-bh-ttf := 1.0.3
font-bh-type1 := 1.0.3
font-bitstream-75dpi := 1.0.3
font-bitstream-100dpi := 1.0.3
font-bitstream-speedo := 1.0.2
font-bitstream-type1 := 1.0.3
font-cronyx-cyrillic := 1.0.3
font-cursor-misc := 1.0.3
font-daewoo-misc := 1.0.3
font-dec-misc := 1.0.3
font-ibm-type1 := 1.0.3
font-isas-misc := 1.0.3
font-jis-misc := 1.0.3
font-micro-misc := 1.0.3
font-misc-cyrillic := 1.0.3
font-misc-ethiopic := 1.0.4
font-misc-meltho := 1.0.3
font-misc-misc := 1.1.2
font-mutt-misc := 1.0.3
font-schumacher-misc := 1.1.2
font-screen-cyrillic := 1.0.4
font-sony-misc := 1.0.3
font-sun-misc := 1.0.3
font-winitzki-cyrillic := 1.0.3
font-xfree86-type1 := 1.0.4
DEB_FONTS_V   ?= $(FONTS_VERSION)

fonts-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-adobe-75dpi-$(font-adobe-75dpi).tar.gz
	$(call EXTRACT_TAR,font-adobe-75dpi-$(font-adobe-75dpi).tar.gz,font-adobe-75dpi-$(font-adobe-75dpi),font-adobe-75dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-adobe-100dpi-$(font-adobe-100dpi).tar.gz
	$(call EXTRACT_TAR,font-adobe-100dpi-$(font-adobe-100dpi).tar.gz,font-adobe-100dpi-$(font-adobe-100dpi),font-adobe-100dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-adobe-utopia-75dpi-$(font-adobe-utopia-75dpi).tar.gz
	$(call EXTRACT_TAR,font-adobe-utopia-75dpi-$(font-adobe-utopia-75dpi).tar.gz,font-adobe-utopia-75dpi-$(font-adobe-utopia-75dpi),font-adobe-utopia-75dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-adobe-utopia-100dpi-$(font-adobe-utopia-100dpi).tar.gz
	$(call EXTRACT_TAR,font-adobe-utopia-100dpi-$(font-adobe-utopia-100dpi).tar.gz,font-adobe-utopia-100dpi-$(font-adobe-utopia-100dpi),font-adobe-utopia-100dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-adobe-utopia-type1-$(font-adobe-utopia-type1).tar.gz
	$(call EXTRACT_TAR,font-adobe-utopia-type1-$(font-adobe-utopia-type1).tar.gz,font-adobe-utopia-type1-$(font-adobe-utopia-type1),font-adobe-utopia-type1)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-arabic-misc-$(font-arabic-misc).tar.gz
	$(call EXTRACT_TAR,font-arabic-misc-$(font-arabic-misc).tar.gz,font-arabic-misc-$(font-arabic-misc),font-arabic-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bh-75dpi-$(font-bh-75dpi).tar.gz
	$(call EXTRACT_TAR,font-bh-75dpi-$(font-bh-75dpi).tar.gz,font-bh-75dpi-$(font-bh-75dpi),font-bh-75dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bh-100dpi-$(font-bh-100dpi).tar.gz
	$(call EXTRACT_TAR,font-bh-100dpi-$(font-bh-100dpi).tar.gz,font-bh-100dpi-$(font-bh-100dpi),font-bh-100dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bh-lucidatypewriter-75dpi-$(font-bh-lucidatypewriter-75dpi).tar.gz
	$(call EXTRACT_TAR,font-bh-lucidatypewriter-75dpi-$(font-bh-lucidatypewriter-75dpi).tar.gz,font-bh-lucidatypewriter-75dpi-$(font-bh-lucidatypewriter-75dpi),font-bh-lucidatypewriter-75dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bh-lucidatypewriter-100dpi-$(font-bh-lucidatypewriter-100dpi).tar.gz
	$(call EXTRACT_TAR,font-bh-lucidatypewriter-100dpi-$(font-bh-lucidatypewriter-100dpi).tar.gz,font-bh-lucidatypewriter-100dpi-$(font-bh-lucidatypewriter-100dpi),font-bh-lucidatypewriter-100dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bh-ttf-$(font-bh-ttf).tar.gz
	$(call EXTRACT_TAR,font-bh-ttf-$(font-bh-ttf).tar.gz,font-bh-ttf-$(font-bh-ttf),font-bh-ttf)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bh-type1-$(font-bh-type1).tar.gz
	$(call EXTRACT_TAR,font-bh-type1-$(font-bh-type1).tar.gz,font-bh-type1-$(font-bh-type1),font-bh-type1)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bitstream-75dpi-$(font-bitstream-75dpi).tar.gz
	$(call EXTRACT_TAR,font-bitstream-75dpi-$(font-bitstream-75dpi).tar.gz,font-bitstream-75dpi-$(font-bitstream-75dpi),font-bitstream-75dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bitstream-100dpi-$(font-bitstream-100dpi).tar.gz
	$(call EXTRACT_TAR,font-bitstream-100dpi-$(font-bitstream-100dpi).tar.gz,font-bitstream-100dpi-$(font-bitstream-100dpi),font-bitstream-100dpi)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bitstream-speedo-$(font-bitstream-speedo).tar.gz
	$(call EXTRACT_TAR,font-bitstream-speedo-$(font-bitstream-speedo).tar.gz,font-bitstream-speedo-$(font-bitstream-speedo),font-bitstream-speedo)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-bitstream-type1-$(font-bitstream-type1).tar.gz
	$(call EXTRACT_TAR,font-bitstream-type1-$(font-bitstream-type1).tar.gz,font-bitstream-type1-$(font-bitstream-type1),font-bitstream-type1)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-cronyx-cyrillic-$(font-cronyx-cyrillic).tar.gz
	$(call EXTRACT_TAR,font-cronyx-cyrillic-$(font-cronyx-cyrillic).tar.gz,font-cronyx-cyrillic-$(font-cronyx-cyrillic),font-cronyx-cyrillic)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-cursor-misc-$(font-cursor-misc).tar.gz
	$(call EXTRACT_TAR,font-cursor-misc-$(font-cursor-misc).tar.gz,font-cursor-misc-$(font-cursor-misc),font-cursor-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-daewoo-misc-$(font-daewoo-misc).tar.gz
	$(call EXTRACT_TAR,font-daewoo-misc-$(font-daewoo-misc).tar.gz,font-daewoo-misc-$(font-daewoo-misc),font-daewoo-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-dec-misc-$(font-dec-misc).tar.gz
	$(call EXTRACT_TAR,font-dec-misc-$(font-dec-misc).tar.gz,font-dec-misc-$(font-dec-misc),font-dec-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-ibm-type1-$(font-ibm-type1).tar.gz
	$(call EXTRACT_TAR,font-ibm-type1-$(font-ibm-type1).tar.gz,font-ibm-type1-$(font-ibm-type1),font-ibm-type1)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-isas-misc-$(font-isas-misc).tar.gz
	$(call EXTRACT_TAR,font-isas-misc-$(font-isas-misc).tar.gz,font-isas-misc-$(font-isas-misc),font-isas-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-jis-misc-$(font-jis-misc).tar.gz
	$(call EXTRACT_TAR,font-jis-misc-$(font-jis-misc).tar.gz,font-jis-misc-$(font-jis-misc),font-jis-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-micro-misc-$(font-micro-misc).tar.gz
	$(call EXTRACT_TAR,font-micro-misc-$(font-micro-misc).tar.gz,font-micro-misc-$(font-micro-misc),font-micro-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-misc-cyrillic-$(font-misc-cyrillic).tar.gz
	$(call EXTRACT_TAR,font-misc-cyrillic-$(font-misc-cyrillic).tar.gz,font-misc-cyrillic-$(font-misc-cyrillic),font-misc-cyrillic)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-misc-ethiopic-$(font-misc-ethiopic).tar.gz
	$(call EXTRACT_TAR,font-misc-ethiopic-$(font-misc-ethiopic).tar.gz,font-misc-ethiopic-$(font-misc-ethiopic),font-misc-ethiopic)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-misc-meltho-$(font-misc-meltho).tar.gz
	$(call EXTRACT_TAR,font-misc-meltho-$(font-misc-meltho).tar.gz,font-misc-meltho-$(font-misc-meltho),font-misc-meltho)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-misc-misc-$(font-misc-misc).tar.gz
	$(call EXTRACT_TAR,font-misc-misc-$(font-misc-misc).tar.gz,font-misc-misc-$(font-misc-misc),font-misc-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-mutt-misc-$(font-mutt-misc).tar.gz
	$(call EXTRACT_TAR,font-mutt-misc-$(font-mutt-misc).tar.gz,font-mutt-misc-$(font-mutt-misc),font-mutt-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-schumacher-misc-$(font-schumacher-misc).tar.gz
	$(call EXTRACT_TAR,font-schumacher-misc-$(font-schumacher-misc).tar.gz,font-schumacher-misc-$(font-schumacher-misc),font-schumacher-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-screen-cyrillic-$(font-screen-cyrillic).tar.gz
	$(call EXTRACT_TAR,font-screen-cyrillic-$(font-screen-cyrillic).tar.gz,font-screen-cyrillic-$(font-screen-cyrillic),font-screen-cyrillic)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-sony-misc-$(font-sony-misc).tar.gz
	$(call EXTRACT_TAR,font-sony-misc-$(font-sony-misc).tar.gz,font-sony-misc-$(font-sony-misc),font-sony-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-sun-misc-$(font-sun-misc).tar.gz
	$(call EXTRACT_TAR,font-sun-misc-$(font-sun-misc).tar.gz,font-sun-misc-$(font-sun-misc),font-sun-misc)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-winitzki-cyrillic-$(font-winitzki-cyrillic).tar.gz
	$(call EXTRACT_TAR,font-winitzki-cyrillic-$(font-winitzki-cyrillic).tar.gz,font-winitzki-cyrillic-$(font-winitzki-cyrillic),font-winitzki-cyrillic)
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/font/font-xfree86-type1-$(font-xfree86-type1).tar.gz
	$(call EXTRACT_TAR,font-xfree86-type1-$(font-xfree86-type1).tar.gz,font-xfree86-type1-$(font-xfree86-type1),font-xfree86-type1)

ifneq ($(wildcard $(BUILD_WORK)/font-xfree86-type1/.build_complete),)
fonts:
	@echo "Using previously built all fonts."
else
fonts: fonts-setup 
	cd $(BUILD_WORK)/font-adobe-75dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-75dpi
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-75dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-75dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-adobe-75dpi/.build_complete

	cd $(BUILD_WORK)/font-adobe-100dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-100dpi
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-100dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-100dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-adobe-100dpi/.build_complete

	cd $(BUILD_WORK)/font-adobe-utopia-75dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-75dpi
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-75dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-75dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-adobe-utopia-75dpi/.build_complete

	cd $(BUILD_WORK)/font-adobe-utopia-100dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-100dpi
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-100dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-100dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-adobe-utopia-100dpi/.build_complete

	cd $(BUILD_WORK)/font-adobe-utopia-type1 && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-type1
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-type1 install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-adobe-utopia-type1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-adobe-utopia-type1/.build_complete

	cd $(BUILD_WORK)/font-arabic-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-arabic-misc
	+$(MAKE) -C $(BUILD_WORK)/font-arabic-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-arabic-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-arabic-misc/.build_complete

	cd $(BUILD_WORK)/font-bh-75dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bh-75dpi
	+$(MAKE) -C $(BUILD_WORK)/font-bh-75dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bh-75dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bh-75dpi/.build_complete

	cd $(BUILD_WORK)/font-bh-100dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bh-100dpi
	+$(MAKE) -C $(BUILD_WORK)/font-bh-100dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bh-100dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bh-100dpi/.build_complete

	cd $(BUILD_WORK)/font-bh-lucidatypewriter-75dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bh-lucidatypewriter-75dpi
	+$(MAKE) -C $(BUILD_WORK)/font-bh-lucidatypewriter-75dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bh-lucidatypewriter-75dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bh-lucidatypewriter-75dpi/.build_complete

	cd $(BUILD_WORK)/font-bh-lucidatypewriter-100dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bh-lucidatypewriter-100dpi
	+$(MAKE) -C $(BUILD_WORK)/font-bh-lucidatypewriter-100dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bh-lucidatypewriter-100dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bh-lucidatypewriter-100dpi/.build_complete

	cd $(BUILD_WORK)/font-bh-ttf && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bh-ttf
	+$(MAKE) -C $(BUILD_WORK)/font-bh-ttf install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bh-ttf install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bh-ttf/.build_complete

	cd $(BUILD_WORK)/font-bh-type1 && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bh-type1
	+$(MAKE) -C $(BUILD_WORK)/font-bh-type1 install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bh-type1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bh-type1/.build_complete

	cd $(BUILD_WORK)/font-bitstream-75dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-75dpi
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-75dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-75dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bitstream-75dpi/.build_complete

	cd $(BUILD_WORK)/font-bitstream-100dpi && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-100dpi
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-100dpi install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-100dpi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bitstream-100dpi/.build_complete

	cd $(BUILD_WORK)/font-bitstream-speedo && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-speedo
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-speedo install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-speedo install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bitstream-speedo/.build_complete

	cd $(BUILD_WORK)/font-bitstream-type1 && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-type1
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-type1 install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-bitstream-type1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-bitstream-type1/.build_complete

	cd $(BUILD_WORK)/font-cronyx-cyrillic && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-cronyx-cyrillic
	+$(MAKE) -C $(BUILD_WORK)/font-cronyx-cyrillic install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-cronyx-cyrillic install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-cronyx-cyrillic/.build_complete

	cd $(BUILD_WORK)/font-cursor-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-cursor-misc
	+$(MAKE) -C $(BUILD_WORK)/font-cursor-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-cursor-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-cursor-misc/.build_complete

	cd $(BUILD_WORK)/font-daewoo-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-daewoo-misc
	+$(MAKE) -C $(BUILD_WORK)/font-daewoo-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-daewoo-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-daewoo-misc/.build_complete

	cd $(BUILD_WORK)/font-dec-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-dec-misc
	+$(MAKE) -C $(BUILD_WORK)/font-dec-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-dec-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-dec-misc/.build_complete

	cd $(BUILD_WORK)/font-ibm-type1 && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-ibm-type1
	+$(MAKE) -C $(BUILD_WORK)/font-ibm-type1 install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-ibm-type1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-ibm-type1/.build_complete

	cd $(BUILD_WORK)/font-isas-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-isas-misc
	+$(MAKE) -C $(BUILD_WORK)/font-isas-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-isas-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-isas-misc/.build_complete

	cd $(BUILD_WORK)/font-jis-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-jis-misc
	+$(MAKE) -C $(BUILD_WORK)/font-jis-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-jis-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-jis-misc/.build_complete

	cd $(BUILD_WORK)/font-micro-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-micro-misc
	+$(MAKE) -C $(BUILD_WORK)/font-micro-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-micro-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-micro-misc/.build_complete

	cd $(BUILD_WORK)/font-misc-cyrillic && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-misc-cyrillic
	+$(MAKE) -C $(BUILD_WORK)/font-misc-cyrillic install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-misc-cyrillic install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-misc-cyrillic/.build_complete

	cd $(BUILD_WORK)/font-misc-ethiopic && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-misc-ethiopic
	+$(MAKE) -C $(BUILD_WORK)/font-misc-ethiopic install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-misc-ethiopic install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-misc-ethiopic/.build_complete

	cd $(BUILD_WORK)/font-misc-meltho && autoreconf -fiv && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-misc-meltho
	+$(MAKE) -C $(BUILD_WORK)/font-misc-meltho install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-misc-meltho install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-misc-meltho/.build_complete

	cd $(BUILD_WORK)/font-misc-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-misc-misc
	+$(MAKE) -C $(BUILD_WORK)/font-misc-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-misc-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-misc-misc/.build_complete

	cd $(BUILD_WORK)/font-mutt-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-mutt-misc
	+$(MAKE) -C $(BUILD_WORK)/font-mutt-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-mutt-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-mutt-misc/.build_complete

	cd $(BUILD_WORK)/font-schumacher-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/font-schumacher-misc
	+$(MAKE) -C $(BUILD_WORK)/font-schumacher-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-schumacher-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-schumacher-misc/.build_complete

	cd $(BUILD_WORK)/font-screen-cyrillic && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/font-screen-cyrillic
	+$(MAKE) -C $(BUILD_WORK)/font-screen-cyrillic install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-screen-cyrillic install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-screen-cyrillic/.build_complete

	cd $(BUILD_WORK)/font-sony-misc && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/font-sony-misc
	+$(MAKE) -C $(BUILD_WORK)/font-sony-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-sony-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-sony-misc/.build_complete

	cd $(BUILD_WORK)/font-sun-misc && autoreconf -fiv && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/font-sun-misc
	+$(MAKE) -C $(BUILD_WORK)/font-sun-misc install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-sun-misc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-sun-misc/.build_complete

	cd $(BUILD_WORK)/font-winitzki-cyrillic && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/font-winitzki-cyrillic
	+$(MAKE) -C $(BUILD_WORK)/font-winitzki-cyrillic install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-winitzki-cyrillic install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-winitzki-cyrillic/.build_complete

	cd $(BUILD_WORK)/font-xfree86-type1 && autoreconf -fiv && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/font-xfree86-type1
	+$(MAKE) -C $(BUILD_WORK)/font-xfree86-type1 install \
		DESTDIR=$(BUILD_STAGE)/fonts
	+$(MAKE) -C $(BUILD_WORK)/font-xfree86-type1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/font-xfree86-type1/.build_complete
endif

fonts-package: fonts-stage
# fonts.mk Package Structure
	rm -rf $(BUILD_DIST)/fonts
	
# fonts.mk Prep fonts
	cp -a $(BUILD_STAGE)/fonts $(BUILD_DIST)
	
# fonts.mk Sign
	$(call SIGN,fonts,general.xml)
	
# fonts.mk Make .debs
	$(call PACK,fonts,DEB_FONTS_V)
	
# fonts.mk Build cleanup
	rm -rf $(BUILD_DIST)/fonts

.PHONY: fonts fonts-package