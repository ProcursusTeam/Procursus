ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += libutf8proc
LIBUTF8PROC_VERSION   := 2.5.0
DEB_LIBUTF8PROC_V     ?= $(LIBUTF8PROC_VERSION)

libutf8proc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/JuliaStrings/utf8proc/archive/v$(LIBUTF8PROC_VERSION).tar.gz
	$(call EXTRACT_TAR,v$(LIBUTF8PROC_VERSION).tar.gz,utf8proc-$(LIBUTF8PROC_VERSION),libutf8proc)

ifneq ($(wildcard $(BUILD_WORK)/libutf8proc/.build_complete),)
libutf8proc:
	@echo "Using previously built libutf8proc."
else
libutf8proc: libutf8proc-setup
	+$(MAKE) -C $(BUILD_WORK)/libutf8proc install \
		OS=Darwin \
		prefix=/usr \
		DESTDIR="$(BUILD_STAGE)/libutf8proc"
	+$(MAKE) -C $(BUILD_WORK)/libutf8proc install \
		OS=Darwin \
		prefix=/usr \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libutf8proc/.build_complete
endif

libutf8proc-package: libutf8proc-stage
	# libutf8proc.mk Package Structure
	rm -rf $(BUILD_DIST)/libutf8proc
	mkdir -p $(BUILD_DIST)/libutf8proc
	
	# libutf8proc.mk Prep libutf8proc
	cp -a $(BUILD_STAGE)/libutf8proc/usr $(BUILD_DIST)/libutf8proc
	
	# libutf8proc.mk Sign
	$(call SIGN,libutf8proc,libutf8proc.xml)
	
	# libutf8proc.mk Make .debs
	$(call PACK,libutf8proc,DEB_LIBUTF8PROC_V)
	
	# libutf8proc.mk Build cleanup
	rm -rf $(BUILD_DIST)/libutf8proc

.PHONY: libutf8proc libutf8proc-package
