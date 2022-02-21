ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pidof
PIDOF_VERSION := 0.1.4
PIDOF_SHA1    := 150ff344d7065ecf9bc5cb3c2cc83eeda8d31348
DEB_PIDOF_V   ?= $(PIDOF_VERSION)

# Licensing: see pidof.1

pidof-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://www.nightproductions.net/downloads/pidof_source.tar.gz
	$(call CHECKSUM_VERIFY,sha1,pidof_source.tar.gz,$(PIDOF_SHA1))
	$(call EXTRACT_TAR,pidof_source.tar.gz,pidof-source,pidof)
	sed -i '1s|^|#import <string.h>\n#import <signal.h>\n|' $(BUILD_WORK)/pidof/pidof.c
	sed -i -e 's/Print out/Prints out/g' -e 's/gettting/getting/g' $(BUILD_WORK)/pidof/pidof.c
	mkdir -p $(BUILD_STAGE)/pidof/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

ifneq ($(wildcard $(BUILD_WORK)/pidof/.build_complete),)
pidof:
	@echo "Using previously built pidof."
else
pidof: pidof-setup
	$(CC) -std=c89 $(CFLAGS) $(LDFLAGS) $(BUILD_WORK)/pidof/pidof.c -o $(BUILD_STAGE)/pidof/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pidof
	install -m644 $(BUILD_WORK)/pidof/pidof.1 $(BUILD_STAGE)/pidof/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(call AFTER_BUILD)
endif

pidof-package: pidof-stage
	# pidof.mk Package Structure
	rm -rf $(BUILD_DIST)/pidof

	# pidof.mk Prep pidof
	cp -a $(BUILD_STAGE)/pidof $(BUILD_DIST)

	# pidof.mk Sign
	$(call SIGN,pidof,general.xml)

	# pidof.mk Make .debs
	$(call PACK,pidof,DEB_PIDOF_V)

	# pidof.mk Build cleanup
	rm -rf $(BUILD_DIST)/pidof

.PHONY: pidof pidof-package
