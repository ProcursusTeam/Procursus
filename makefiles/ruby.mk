ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += ruby
RUBY_VERSION     := 3.0
RUBY_API_VERSION := $(RUBY_VERSION).1
DEB_RUBY_V       ?= $(RUBY_API_VERSION)-1

ruby-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://cache.ruby-lang.org/pub/ruby/$(RUBY_VERSION)/ruby-$(RUBY_API_VERSION).tar.gz
	$(call EXTRACT_TAR,ruby-$(RUBY_API_VERSION).tar.gz,ruby-$(RUBY_API_VERSION),ruby)
	$(call DO_PATCH,ruby,ruby,-p1)


ifneq (,$(findstring amd64,$(MEMO_TARGET)))
RUBY_CONFIGURE_ARGS := --with-coroutine=amd64
else
RUBY_CONFIGURE_ARGS := --with-coroutine=arm64
endif

ifneq ($(wildcard $(BUILD_WORK)/ruby/.build_complete),)
ruby:
	@echo "Using previously built ruby."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
RUBY_EXTRA_LIBS     := -lcrypt
ruby: ruby-setup libxcrypt libgmp10 libjemalloc ncurses readline openssl libyaml libffi libgdbm
else
RUBY_EXTRA_LIBS     :=
ruby: ruby-setup libgmp10 libjemalloc ncurses readline openssl libyaml libffi libgdbm
endif
#	mkdir -p $(BUILD_WORK)/ruby/nativebuild
#	cd $(BUILD_WORK)/ruby/nativebuild && env -i ../configure --prefix=$(BUILD_WORK)/ruby/nativebuild/install --disable-install-rdoc --disable-install-doc
#	+unset CC CXX CFLAGS CPPFLAGS LDFLAGS && $(MAKE) -C $(BUILD_WORK)/ruby/nativebuild install

	$(SED) -i -e 's/\bcurses\b/ncursesw/' \
		-e 's/\bncurses\b/ncursesw/' $(BUILD_WORK)/ruby/ext/readline/extconf.rb

#	Future reference: coroutine should be "arm64" on M1 macs
	cd $(BUILD_WORK)/ruby && LIBS="$(RUBY_EXTRA_LIBS)" \
		./configure -C \
			$(DEFAULT_CONFIGURE_FLAGS) \
			--target=$(GNU_HOST_TRIPLE) \
			--with-arch=$(MEMO_ARCH) \
			--with-jemalloc \
			--enable-shared \
			--program-suffix=$(RUBY_VERSION) \
			--with-soname=ruby-$(RUBY_VERSION) \
			--with-sitedir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/ruby/site_ruby \
			--with-vendordir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ruby/vendor_ruby \
			--runstatedir=$(MEMO_PREFIX)/var/run \
			--disable-dtrace \
			--enable-ipv6 \
			--with-baseruby="$(shell which ruby)" \
			$(RUBY_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/ruby
	+$(MAKE) -C $(BUILD_WORK)/ruby install \
		DESTDIR="$(BUILD_STAGE)/ruby"
	$(SED) -i 's/.*DLDFLAGS=.*/DLDFLAGS=/' $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/ruby-$(RUBY_VERSION).pc
	touch $(BUILD_WORK)/ruby/.build_complete
endif

ruby-package: ruby-stage
	# ruby.mk Package Structure
	rm -rf $(BUILD_DIST)/ruby$(RUBY_VERSION){,-dev,-doc} $(BUILD_DIST)/libruby$(RUBY_VERSION) $(BUILD_DIST)/ruby
	mkdir -p $(BUILD_DIST)/ruby$(RUBY_VERSION){,-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/ruby$(RUBY_VERSION)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libruby$(RUBY_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# ruby.mk Prep ruby$(RUBY_VERSION)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/ruby$(RUBY_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/ruby$(RUBY_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# ruby.mk Prep ruby$(RUBY_VERSION)-dev
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/ruby$(RUBY_VERSION)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/ruby$(RUBY_VERSION)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ruby.mk Prep ruby$(RUBY_VERSION)-doc
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/ri $(BUILD_DIST)/ruby$(RUBY_VERSION)-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# ruby.mk Prep libruby$(RUBY_VERSION)
	cp -a $(BUILD_STAGE)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libruby-$(RUBY_VERSION).dylib,ruby} $(BUILD_DIST)/libruby$(RUBY_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ruby.mk Prep ruby
	for bin in erb irb rdoc ri ruby; do \
		ln -s $${bin}$(RUBY_VERSION) $(BUILD_DIST)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin}; \
		ln -s $${bin}$(RUBY_VERSION).1.zst $(BUILD_DIST)/ruby/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$${bin}.1; \
	done

	# ruby.mk Sign
	$(call SIGN,ruby$(RUBY_VERSION),general.xml)
	$(call SIGN,libruby$(RUBY_VERSION),general.xml)

	# ruby.mk Make .debs
	$(call PACK,ruby,DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_VERSION),DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_VERSION)-dev,DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_VERSION)-doc,DEB_RUBY_V)
	$(call PACK,libruby$(RUBY_VERSION),DEB_RUBY_V)

	# ruby.mk Build cleanup
	rm -rf $(BUILD_DIST)/ruby$(RUBY_VERSION){,-dev,-doc} $(BUILD_DIST)/libruby$(RUBY_VERSION) $(BUILD_DIST)/ruby

.PHONY: ruby ruby-package
