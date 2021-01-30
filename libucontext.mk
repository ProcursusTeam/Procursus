ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libucontext
LIBUCONTEXT_COMMIT := 455ecd495f706d5b57be3ff5b572c120c2a7a5a2

libucontext-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libucontext-$(LIBUCONTEXT_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libucontext-$(LIBUCONTEXT_COMMIT).tar.gz \
			https://github.com/utmapp/libucontext/archive/$(LIBUCONTEXT_COMMIT).tar.gz
	$(call EXTRACT_TAR,libucontext-$(LIBUCONTEXT_COMMIT).tar.gz,libucontext-$(LIBUCONTEXT_COMMIT),libucontext)

ifneq ($(wildcard $(BUILD_WORK)/libucontext/.build_complete),)
libucontext:
	@echo "Using previously built libucontext."
else
libucontext: libucontext-setup
	+$(MAKE) -C $(BUILD_WORK)/libucontext all \
		ARCH=aarch64
	mkdir -p $(BUILD_STAGE)/libucontext/usr/lib
	cp -a $(BUILD_WORK)/libucontext/libucontext.a $(BUILD_STAGE)/libucontext/usr/lib
	cp -a $(BUILD_WORK)/libucontext/include $(BUILD_STAGE)/libucontext/usr
	touch $(BUILD_WORK)/libucontext/.build_complete
endif

.PHONY: libucontext
