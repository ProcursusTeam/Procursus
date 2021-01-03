ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += cowsay
COWSAY_VERSION := 3.04
DEB_COWSAY_V   ?= $(COWSAY_VERSION)

cowsay-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tnalpgge/rank-amateur-cowsay/archive/cowsay-$(COWSAY_VERSION).tar.gz
	$(call EXTRACT_TAR,cowsay-$(COWSAY_VERSION).tar.gz,rank-amateur-cowsay-cowsay-$(COWSAY_VERSION),cowsay)
	mkdir -p $(BUILD_STAGE)/cowsay/usr/{games,share/man/man1}

ifneq ($(wildcard $(BUILD_WORK)/cowsay/.build_complete),)
cowsay:
	@echo "Using previously built cowsay."
else
cowsay: cowsay-setup
	$(SED) -i -e 's|%BANGPERL%|!/usr/bin/perl|' -e 's|%PREFIX%|/usr|' $(BUILD_WORK)/cowsay/cowsay $(BUILD_WORK)/cowsay/cowsay.1
	cp -a $(BUILD_WORK)/cowsay/cowsay $(BUILD_STAGE)/cowsay/usr/games
	cp -a $(BUILD_WORK)/cowsay/cowsay.1 $(BUILD_STAGE)/cowsay/usr/share/man/man1
	cp -a $(BUILD_WORK)/cowsay/cows $(BUILD_STAGE)/cowsay/usr/share
	ln -s cowsay $(BUILD_STAGE)/cowsay/usr/games/cowthink
	ln -s cowsay.1.zst $(BUILD_STAGE)/cowsay/usr/share/man/man1/cowthink.1
	touch $(BUILD_WORK)/cowsay/.build_complete
endif

cowsay-package: cowsay-stage
	# cowsay.mk Package Structure
	rm -rf $(BUILD_DIST)/cowsay{,-off}
	mkdir -p $(BUILD_DIST)/cowsay{,-off}/usr/share/cows
	
	# cowsay.mk Prep cowsay
	cp -a $(BUILD_STAGE)/cowsay/usr/games $(BUILD_DIST)/cowsay/usr
	cp -a $(BUILD_STAGE)/cowsay/usr/share/man $(BUILD_DIST)/cowsay/usr/share
	cp -a $(BUILD_STAGE)/cowsay/usr/share/cows/!(beavis.zen.cow|bong.cow|mutilated.cow|head-in.cow) $(BUILD_DIST)/cowsay/usr/share/cows
	
	# cowsay.mk Prep cowsay-off
	cp -a $(BUILD_STAGE)/cowsay/usr/share/cows/{beavis.zen.cow,bong.cow,mutilated.cow,head-in.cow} $(BUILD_DIST)/cowsay-off/usr/share/cows
	
	# cowsay.mk Make .debs
	$(call PACK,cowsay,DEB_COWSAY_V)
	$(call PACK,cowsay-off,DEB_COWSAY_V)
	
	# cowsay.mk Build cleanup
	rm -rf $(BUILD_DIST)/cowsay{,-off}

.PHONY: cowsay cowsay-package
