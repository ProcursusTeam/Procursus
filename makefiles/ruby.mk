ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += ruby
RUBY_API_VERSION := 3.1
RUBY_VERSION     := $(RUBY_API_VERSION).2
DEB_RUBY_V       ?= $(RUBY_VERSION)

ruby-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://cache.ruby-lang.org/pub/ruby/$(RUBY_API_VERSION)/ruby-$(RUBY_VERSION).tar.gz)
	$(call EXTRACT_TAR,ruby-$(RUBY_VERSION).tar.gz,ruby-$(RUBY_VERSION),ruby)

ifneq (,$(findstring amd64,$(MEMO_TARGET)))
RUBY_CONFIGURE_ARGS := --with-coroutine=amd64
else
RUBY_CONFIGURE_ARGS := --with-coroutine=arm64
endif

ifneq ($(wildcard $(BUILD_WORK)/ruby/.build_complete),)
ruby:
	@echo "Using previously built ruby."
else
ruby: ruby-setup libxcrypt libgmp10 libjemalloc ncurses readline openssl libyaml libffi
	mkdir -p $(BUILD_WORK)/ruby/nativebuild
	cd $(BUILD_WORK)/ruby/nativebuild && env -i ../configure $(BUILD_CONFIGURE_FLAGS) --prefix=$(BUILD_WORK)/ruby/nativebuild/install --disable-install-rdoc --disable-install-doc
	+$(MAKE) -C $(BUILD_WORK)/ruby/nativebuild install

	sed -i -e 's/\bcurses\b/ncursesw/' \
		-e 's/\bncurses\b/ncursesw/' $(BUILD_WORK)/ruby/ext/readline/extconf.rb

	cd $(BUILD_WORK)/ruby && LIBS="-lcrypt" \
		./configure -C \
			$(DEFAULT_CONFIGURE_FLAGS) \
			--target=$(GNU_HOST_TRIPLE) \
			--with-arch=$(MEMO_ARCH) \
			--with-jemalloc \
			--enable-shared \
			--program-suffix=$(RUBY_API_VERSION) \
			--with-soname=ruby-$(RUBY_API_VERSION) \
			--with-sitedir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/ruby/site_ruby \
			--with-vendordir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ruby/vendor_ruby \
			--runstatedir=$(MEMO_PREFIX)/var/run \
			--disable-dtrace \
			--enable-ipv6 \
			--with-baseruby="$(BUILD_WORK)/ruby/nativebuild/install/bin/ruby" \
			$(RUBY_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/ruby
	+$(MAKE) -C $(BUILD_WORK)/ruby install \
		DESTDIR="$(BUILD_STAGE)/ruby"
	sed -i 's/.*DLDFLAGS=.*/DLDFLAGS=/' $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/ruby-$(RUBY_API_VERSION).pc
	$(call AFTER_BUILD)
endif

ruby-package: ruby-stage
	# ruby.mk Package Structure
	rm -rf $(BUILD_DIST)/ruby$(RUBY_API_VERSION){,-dev,-doc} $(BUILD_DIST)/libruby$(RUBY_API_VERSION) $(BUILD_DIST)/ruby
	mkdir -p $(BUILD_DIST)/ruby$(RUBY_API_VERSION){,-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/ruby$(RUBY_API_VERSION)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libruby$(RUBY_API_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# ruby.mk Prep ruby$(RUBY_API_VERSION)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/ruby$(RUBY_API_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/ruby$(RUBY_API_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# ruby.mk Prep ruby$(RUBY_API_VERSION)-dev
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/ruby$(RUBY_API_VERSION)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/ruby$(RUBY_API_VERSION)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ruby.mk Prep ruby$(RUBY_API_VERSION)-doc
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/ri $(BUILD_DIST)/ruby$(RUBY_API_VERSION)-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# ruby.mk Prep libruby$(RUBY_API_VERSION)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libruby-$(RUBY_API_VERSION).dylib,ruby} $(BUILD_DIST)/libruby$(RUBY_API_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ruby.mk Prep ruby
	for bin in erb irb rdoc ri ruby; do \
		$(LN_S) $${bin}$(RUBY_API_VERSION) $(BUILD_DIST)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin}; \
		$(LN_S) $${bin}$(RUBY_API_VERSION).1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$${bin}.1; \
	done

	# ruby.mk Sign
	$(call SIGN,ruby$(RUBY_API_VERSION),general.xml)
	$(call SIGN,libruby$(RUBY_API_VERSION),general.xml)

	# ruby.mk Make .debs
	$(call PACK,ruby,DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_API_VERSION),DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_API_VERSION)-dev,DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_API_VERSION)-doc,DEB_RUBY_V)
	$(call PACK,libruby$(RUBY_API_VERSION),DEB_RUBY_V)

	# ruby.mk Build cleanup
	rm -rf $(BUILD_DIST)/ruby$(RUBY_API_VERSION){,-dev,-doc} $(BUILD_DIST)/libruby$(RUBY_API_VERSION) $(BUILD_DIST)/ruby

.PHONY: ruby ruby-package
