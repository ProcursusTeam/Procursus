ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif
SUBPROJECTS   += nginx
NGINX_VERSION := 1.21.5
DEB_NGINX_V   ?= $(NGINX_VERSION)

ifeq ($(UNAME),Darwin)
CC := /usr/bin/cc
endif

GLOBAL_NGINX_FLAGS := --prefix=$(MEMO_PREFIX)/etc/nginx \
					   --sbin-path=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/nginx \
					   --conf-path=$(MEMO_PREFIX)/etc/nginx/nginx.conf \
					   --modules-path=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules \
					   --pid-path=$(MEMO_PREFIX)/var/nginx/nginx.pid \
					   --lock-path=$(MEMO_PREFIX)/var/nginx/nginx.lock \
					   --http-log-path=$(MEMO_PREFIX)/var/log/nginx/access.log \
					   --error-log-path=$(MEMO_PREFIX)/var/log/nginx/error.log \
					   --with-cc-opt="$(CFLAGS) $(CXXFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
					   --with-ld-opt="$(LDFLAGS) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
					   --with-compat \
					   --with-debug \
					   --with-pcre-jit \
					   --with-threads \
					   --with-http_ssl_module \
			           --with-http_stub_status_module \
			           --with-http_realip_module \
			           --with-http_auth_request_module \
			           --with-http_v2_module \
			           --with-http_dav_module \
			           --with-http_slice_module

LIGHT_NGINX_FLAGS := $(GLOBAL_NGINX_FLAGS) \
					   --with-http_addition_module

CORE_NGINX_FLAGS := $(GLOBAL_NGINX_FLAGS) \
					   --with-http_addition_module \
					   --with-http_gunzip_module \
					   --with-http_gzip_static_module \
					   --with-http_sub_module

FULL_NGINX_FLAGS := $(GLOBAL_NGINX_FLAGS) \
            		   --with-http_addition_module \
		               --with-http_flv_module \
		               --with-http_geoip_module=dynamic \
		               --with-http_gunzip_module \
		               --with-http_gzip_static_module \
		               --with-http_image_filter_module=dynamic \
		               --with-http_mp4_module \
  		               --with-http_random_index_module \
  		               --with-http_secure_link_module \
  		               --with-http_sub_module \
  		               --with-http_xslt_module=dynamic \
  		               --with-mail=dynamic \
  		               --with-mail_ssl_module \
  		               --with-stream=dynamic \
  		               --with-stream_geoip_module=dynamic \
  		               --with-stream_ssl_module \
  		               --with-stream_ssl_preread_module

nginx-setup: setup pcre openssl libgeoip libgd libxml2
	wget -q -nc -P$(BUILD_SOURCE) https://nginx.org/download/nginx-$(NGINX_VERSION).tar.gz
	$(call EXTRACT_TAR,nginx-$(NGINX_VERSION).tar.gz,nginx-$(NGINX_VERSION),nginx)
	$(call DO_PATCH,nginx,nginx,-p0)

ifneq ($(wildcard $(BUILD_WORK)/nginx/.build_complete),)
nginx:
	@echo "Using previously built nginx."
else
nginx: nginx-setup
	# do an config for the build machine and then sed out the cflags
	# because nginxs build system doesnt support cross compiling

	# nginx-light
	cd $(BUILD_WORK)/nginx && ./configure \
		$(LIGHT_NGINX_FLAGS)

	sed -i 's|CFLAGS =.*|CFLAGS=$(CFLAGS) $(CPPFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile
	sed -i 's|LINK =.*|LINK=$(CC) $(LDFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile

	+$(MAKE) -C $(BUILD_WORK)/nginx install \
		DESTDIR=$(BUILD_STAGE)/nginx/light

	# nginx-core
	cd $(BUILD_WORK)/nginx && ./configure \
		$(CORE_NGINX_FLAGS)

	sed -i 's|CFLAGS =.*|CFLAGS=$(CFLAGS) $(CPPFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile
	sed -i 's|LINK =.*|LINK=$(CC) $(LDFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile

	+$(MAKE) -C $(BUILD_WORK)/nginx install \
		DESTDIR=$(BUILD_STAGE)/nginx/core

	# nginx-full
	cd $(BUILD_WORK)/nginx && ./configure \
		$(FULL_NGINX_FLAGS)

	sed -i 's|CFLAGS =.*|CFLAGS=$(CFLAGS) $(CPPFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile
	sed -i 's|LINK =.*|LINK=$(CC) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(LDFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile

	+$(MAKE) -C $(BUILD_WORK)/nginx install \
		DESTDIR=$(BUILD_STAGE)/nginx/full

	$(call AFTER_BUILD)
endif

nginx-package: nginx-stage
	# nginx.mk Package Structure
	rm -rf $(BUILD_DIST)/{lib,}nginx*

	# nginx.mk Prep nginx
	cp -a $(BUILD_STAGE)/nginx/core $(BUILD_DIST)/nginx-core
	cp -a $(BUILD_STAGE)/nginx/light $(BUILD_DIST)/nginx-light
	cp -a $(BUILD_STAGE)/nginx/full $(BUILD_DIST)/nginx-full

	install -Dm755 $(BUILD_STAGE)/nginx-full/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_http_image_filter_module.so \
		$(BUILD_DIST)/libnginx-mod-http-image-filter/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_http_image_filter_module.so

	install -Dm755 $(BUILD_STAGE)/nginx-full/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_http_xslt_filter_module.so \
		$(BUILD_DIST)/libnginx-mod-http-xslt-filter/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_http_xslt_filter_module.so

	install -Dm755 $(BUILD_STAGE)/nginx-full/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_mail_module.so \
		$(BUILD_DIST)/libnginx-mod-mail/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_mail_module.so

	install -Dm755 $(BUILD_STAGE)/nginx-full/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_stream_module.so \
		$(BUILD_DIST)/libnginx-mod-stream/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_stream_module.so

	install -Dm755 $(BUILD_STAGE)/nginx-full/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_stream_geoip_module.so \
		$(BUILD_DIST)/libnginx-mod-stream-geoip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_stream_geoip_module.so

	install -Dm755 $(BUILD_STAGE)/nginx-full/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_http_geoip_module.so \
		$(BUILD_DIST)/libnginx-mod-http-geoip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/ngx_http_geoip_module.so

	rm $(BUILD_DIST)/nginx-full/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/nginx/modules/*

	# nginx.mk Sign
	$(call SIGN,nginx-core,general.xml)
	$(call SIGN,nginx-light,general.xml)
	$(call SIGN,nginx-full,general.xml)
	$(call SIGN,libnginx-mod-http-image-filter,general.xml)
	$(call SIGN,libnginx-mod-http-xslt-filter,general.xml)
	$(call SIGN,libnginx-mod-mail,general.xml)
	$(call SIGN,libnginx-mod-stream,general.xml)
	$(call SIGN,libnginx-mod-stream-geoip,general.xml)
	$(call SIGN,libnginx-mod-http-geoip,general.xml)


	$(call PACK,nginx-core,DEB_NGINX_V)
	$(call PACK,nginx-light,DEB_NGINX_V)
	$(call PACK,nginx-full,DEB_NGINX_V)
	$(call PACK,libnginx-mod-http-image-filter,DEB_NGINX_V)
	$(call PACK,libnginx-mod-http-xslt-filter,DEB_NGINX_V)
	$(call PACK,libnginx-mod-mail,DEB_NGINX_V)
	$(call PACK,libnginx-mod-stream,DEB_NGINX_V)
	$(call PACK,libnginx-mod-stream-geoip,DEB_NGINX_V)
	$(call PACK,libnginx-mod-http-geoip,DEB_NGINX_V)

	# nginx.mk Make .debs
	$(call PACK,nginx-core,DEB_NGINX_V)
	$(call PACK,nginx-light,DEB_NGINX_V)
	$(call PACK,nginx-full,DEB_NGINX_V)

	# nginx.mk Build cleanup
	rm -rf $(BUILD_DIST)/nginx-{core,full,light}
	rm -rf $(BUILD_DIST)/libnginx-mod-{http-image-filter,http-xslt-filter,mail,stream,stream-geoip,http-geoip}

.PHONY: nginx nginx-package
