ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += dbus
DBUS_VERSION := 1.12.20
DEB_DBUS_V   ?= $(DBUS_VERSION)

dbus-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dbus.freedesktop.org/releases/dbus/dbus-$(DBUS_VERSION).tar.gz
	$(call EXTRACT_TAR,dbus-$(DBUS_VERSION).tar.gz,dbus-$(DBUS_VERSION),dbus)

ifneq ($(wildcard $(BUILD_WORK)/dbus/.build_complete),)
dbus:
	@echo "Using previously built dbus."
else
dbus: dbus-setup expat glib2.0 libx11 libsm libice
	cd $(BUILD_WORK)/dbus && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
        --enable-user-session \
        --disable-doxygen-docs \
        --disable-xml-docs \
		--enable-launchd \
		--with-launchd-agent-dir=$(MEMO_PREFIX)/Library/LaunchDaemons \
        --with-console-auth-dir=$(MEMO_PREFIX)/var/run/console \
        --with-system-pid-file=$(MEMO_PREFIX)/var/run/dbus/pid \
        --with-system-socket=$(MEMO_PREFIX)/var/run/dbus/system_bus_socket \
		EXPAT_CFLAGS="-I$(TARGET_SYSROOT)/usr/include" \
		EXPAT_LIBS="-L$(TARGET_SYSROOT)/usr/lib -lexpat" \
		PKG_CONFIG="pkg-config --define-prefix"
#		--disable-tests
	+$(MAKE) -C $(BUILD_WORK)/dbus
	+$(MAKE) -C $(BUILD_WORK)/dbus install \
		DESTDIR=$(BUILD_STAGE)/dbus
	+$(MAKE) -C $(BUILD_WORK)/dbus install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/dbus/.build_complete
endif

dbus-package: dbus-stage
	# dbus.mk Package Structure
	rm -rf $(BUILD_DIST)/dbus

	# dbus.mk Prep dbus
	cp -a $(BUILD_STAGE)/dbus $(BUILD_DIST)

	# dbus.mk Sign
	$(call SIGN,dbus,general.xml)

	# dbus.mk Make .debs
	$(call PACK,dbus,DEB_DBUS_V)

	# dbus.mk Build cleanup
	rm -rf $(BUILD_DIST)/dbus

.PHONY: dbus dbus-package
