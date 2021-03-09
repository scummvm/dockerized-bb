BUILDBOT_VERSION   := 3.0.0
BUILDBOT_BASEDIR   := buildbot-workdir

BOTTLE_VERSION     := 0.12.19

# Without toolchains/ part, all is a placeholder for all detected toolchains
TOOLCHAINS_ENABLED := all
TOOLCHAINS_BUILT   := all

# Without workers/ part, all is a placeholder for all detected workers
WORKERS_ENABLED    := all
WORKERS_BUILT      := all

DOCKER_PRIVATE     := 0
DOCKER_REGISTRY    := lephilousophe/scummvm
DOCKER_SEPARATOR   := :

VERBOSE  := 0
BUILDDIR := .build
M4_DEBUG := -dcxaeq

# To let user override previous values easily
# User can also set values on command line
-include Makefile.user

# Helpers

# Create dependencies list based on docker context contents
define MAKE_DEPS
$(BUILDDIR)/$(1): $(shell find $(1)/ -type f) | $(BUILDDIR)/$(patsubst %/,%,$(dir $(1)))
$(if $(wildcard $(1)/Dockerfile.m4),$(BUILDDIR)/$(1): \
   $(shell $(call m4_cmdline,$(1),$(1)/Dockerfile.m4,-di) 2>&1 >/dev/null | sed -e '/^m4debug: input read from /!d; s///;' | tr '\n' ' ') \
,)
endef
# Create a dependency on common (used by toolchains) except when target is not common
define DEPEND_COMMON
$(BUILDDIR)/$(1): \
	$(if $(filter-out common,$(notdir $(1))), \
		$(BUILDDIR)/$(dir $(1))common \
	)
endef
# Create a dependency for $(1) on another image $(2) only if $(1) is present in $(3)
define DEPEND_IMAGE
$(BUILDDIR)/$(strip $(1)): \
	$(if $(filter $(1),$(3)), \
		$(BUILDDIR)/$(strip $(2)) \
	)
endef
# Create a dependency on the toolchain of same name if it exists (used by workers)
define DEPEND_TOOLCHAIN
$(BUILDDIR)/$(1): \
	$(if $(wildcard toolchains/$(notdir $(1))), \
		$(BUILDDIR)/toolchains/$(notdir $(1)) \
	)
endef
# Create a dependency on Makefile
define DEPEND_MAKEFILE
$(BUILDDIR)/$(1): Makefile
endef

m4_cmdline = m4 -P -EE $(3) -I $(dir $(1))m4 -I $(1) toolchains/m4/library.m4 $(2)

# Return the docker URL with path sanitized
build_docker_url = $(DOCKER_REGISTRY)$(DOCKER_SEPARATOR)$(subst /,-,$(1))

# Let's create a list taking whitelist and blacklist into account
# First create a positive list: that takes all words which don't start with a dash,
# if it's the word all, replace it with the 2nd argument,
# else prepend the word with the 3rd argument
positive_list = $(foreach item,$(filter-out -%,$(1)), \
	$(if $(subst xall,,x$(item))$(subst x$(item),,xall), \
		$(3)$(item), \
		$(2) \
	))
# Build the list of negative terms, do not take -all as a special term
# Take only words starting with a dash, remove it and return
negative_list = $(patsubst -%,$(2)%,$(filter -%,$(1)))
# Build a whitelist of all words based on the first argument
# Use the 2nd argument for the all keyword
# Remove the negative terms from the resulting list
# Use the 3rd argument as a prefix
filter_list = $(filter-out $(call negative_list,$(1),$(3)),$(call positive_list,$(1),$(2),$(3)))

# All these targets are directories that should be made
$(BUILDBOT_BASEDIR) $(BUILDDIR) $(BUILDDIR)/toolchains $(BUILDDIR)/workers: %:
	mkdir -p $@

# Debug informations
status:
	@echo "Buildbot version:                 " $(BUILDBOT_VERSION)
	@echo "Timestamps directory:             " $(BUILDDIR)
	@echo "Toolchains to preprocess:         " $(ALL_TOOLCHAINS_M4)
	@echo "Toolchains without preprocessing: " $(ALL_TOOLCHAINS_DOC)
	@echo "All toolchains:                   " $(ALL_TOOLCHAINS)
	@echo "Toolchains enabled:               " $(TOOLCHAINS_ENABLED)
	@echo "Toolchains to build:              " $(TOOLCHAINS_BUILT)
	@echo "Toolchains to download:           " $(TOOLCHAINS_DOWNLOADED)
	@echo "Toolchains online:                " $(TOOLCHAINS_ONLINE)
	@echo "Toolchains timestamps:            " $(TOOLCHAINS_TS)
	@echo "Workers to preprocess:            " $(ALL_WORKERS_M4)
	@echo "Workers without preprocessing:    " $(ALL_WORKERS_DOC)
	@echo "All workers:                      " $(ALL_WORKERS)
	@echo "Workers enabled:                  " $(WORKERS_ENABLED)
	@echo "Workers to build:                 " $(WORKERS_BUILT)
	@echo "Workers to download:              " $(WORKERS_DOWNLOADED)
	@echo "Workers online:                   " $(WORKERS_ONLINE)
	@echo "Workers timestamps:               " $(WORKERS_TS)

# Debug ccache used by workers
ccache-stats:
	@CCACHE_DIR=buildbot-data/ccache ccache -s

check-versions:
	@python3 check-versions/check-versions.py

.PHONY: status ccache-stats check-versions

# Master rules

# Prerequisites are quite redundant but that makes no harm
master: $(BUILDDIR)/buildbot_installed $(BUILDBOT_BASEDIR)/buildbot.tac

# Shortcut to check if config OK for buildbot
# That avoids any downtime at restart if it was bad
# Don't depend on anything to prevent modifying state
master-check:
	@if [ ! -f "$(BUILDBOT_BASEDIR)"/buildbot.tac ]; then \
		echo "Run make master first"; \
		exit 1; \
	fi; \
	cd "$(BUILDBOT_BASEDIR)" && \
		buildbot checkconfig

.PHONY: master master-check

# buildbot depend on Makefile as we modify version here
$(BUILDDIR)/buildbot_installed: Makefile | $(BUILDDIR)
	pip install 'buildbot[bundle]==$(BUILDBOT_VERSION)' \
		'buildbot-wsgi-dashboards==$(BUILDBOT_VERSION)' \
		'bottle==$(BOTTLE_VERSION)'
	touch $(BUILDDIR)/buildbot_installed

# Create startup file once buildbot is installed and up-to-date
# Database setting is loaded from buildbot-config/config.py
# create-master will initialize the database if it doesn't exist yet
# upgrade-master will upgrade it if it needs to be
$(BUILDBOT_BASEDIR)/buildbot.tac: $(BUILDDIR)/buildbot_installed buildbot-config/config.py | $(BUILDBOT_BASEDIR)
	DBLINE=$$(cd buildbot-config && python3 -c 'import config; print(config.db["db_url"])') && \
	       CONFIG_FILE=$$(python3 -c "import os; print(os.path.relpath(os.path.abspath('buildbot-config/master.cfg'), '$(BUILDBOT_BASEDIR)'))") && \
		buildbot create-master -rf --db=$${DBLINE} --config=$${CONFIG_FILE} "$(BUILDBOT_BASEDIR)"
	@rm -f "$(BUILDBOT_BASEDIR)"/master.cfg.sample
	buildbot upgrade-master "$(BUILDBOT_BASEDIR)"
	@rm -f "$(BUILDBOT_BASEDIR)"/master.cfg.sample
	@touch "$(BUILDBOT_BASEDIR)"/buildbot.tac

# Toolchains rules
# List all toolchains: m4 based and raw Dockerfile based
ALL_TOOLCHAINS_M4  := $(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile.m4)))
ALL_TOOLCHAINS_DOC := $(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile)))
ALL_TOOLCHAINS     := $(ALL_TOOLCHAINS_M4) $(ALL_TOOLCHAINS_DOC)

TOOLCHAINS_RESTRICTED := toolchains/apple-sdks toolchains/macosx-arm64 toolchains/macosx-x86_64 toolchains/macosx-i386 toolchains/iphone

# Override because we use the provided value and calculate the real one
override TOOLCHAINS_ENABLED := $(call filter_list,$(TOOLCHAINS_ENABLED),$(ALL_TOOLCHAINS),toolchains/)
override TOOLCHAINS_BUILT   := $(call filter_list,$(TOOLCHAINS_BUILT),$(TOOLCHAINS_ENABLED),toolchains/)
ifeq ($(DOCKER_PRIVATE),1)
	TOOLCHAINS_ONLINE   := $(TOOLCHAINS_ENABLED)
else
	TOOLCHAINS_ONLINE   := $(filter-out $(TOOLCHAINS_RESTRICTED),$(TOOLCHAINS_ENABLED))
endif
TOOLCHAINS_DOWNLOADED       := $(filter-out $(TOOLCHAINS_BUILT),$(TOOLCHAINS_ONLINE))

# Build timestamps files generated as a marker
TOOLCHAINS_M4_TS  := $(foreach i,$(filter $(TOOLCHAINS_BUILT),$(ALL_TOOLCHAINS_M4)),$(BUILDDIR)/$(i))
TOOLCHAINS_DOC_TS := $(foreach i,$(filter $(TOOLCHAINS_BUILT),$(ALL_TOOLCHAINS_DOC)),$(BUILDDIR)/$(i))
TOOLCHAINS_DL_TS  := $(foreach i,$(TOOLCHAINS_DOWNLOADED),$(BUILDDIR)/$(i))
TOOLCHAINS_TS     := $(TOOLCHAINS_M4_TS) $(TOOLCHAINS_DOC_TS) $(TOOLCHAINS_DL_TS)

# Build clean/push/pull rules
TOOLCHAINS_CLEAN := $(foreach i,$(TOOLCHAINS_ENABLED),$(i)/clean)
TOOLCHAINS_PUSH  := $(foreach i,$(TOOLCHAINS_ONLINE),$(i)/push)
TOOLCHAINS_PULL  := $(foreach i,$(TOOLCHAINS_ONLINE),$(i)/pull)

# Phony rules to manage all toolchains easily
toolchains      : $(TOOLCHAINS_ENABLED)
clean-toolchains: $(TOOLCHAINS_CLEAN)
push-toolchains : $(TOOLCHAINS_PUSH)
pull-toolchains : $(TOOLCHAINS_PULL)

# Phony rule to build one toolchain
$(TOOLCHAINS_ENABLED): %: $(BUILDDIR)/%

# Phony rule to clean toolchains
$(TOOLCHAINS_CLEAN): %/clean:
	docker rmi -f $*
	rm -f $(BUILDDIR)/$*

# Phony rules to push and pull images from registry
$(TOOLCHAINS_PUSH): %/push: $(BUILDDIR)/%
	docker tag $* $(call build_docker_url,$*) && \
		docker push $(call build_docker_url,$*) && \
		docker rmi $(call build_docker_url,$*)

# Update timestamp to avoid building image if we got it
# Remove repository tag as it's duplicated
$(TOOLCHAINS_PULL): %/pull: | $(BUILDDIR)/toolchains
	docker pull $(call build_docker_url,$*) && \
		docker tag $(call build_docker_url,$*) $* && \
		docker rmi $(call build_docker_url,$*) && \
		touch -d `docker inspect -f '{{ .Created }}' $*` $(BUILDDIR)/$*

.PHONY: toolchains push-toolchains pull-toolchains clean-toolchains \
	$(TOOLCHAINS_ENABLED) $(TOOLCHAINS_CLEAN) $(TOOLCHAINS_PUSH) $(TOOLCHAINS_PULL)

# Raw Dockerfile toolchains are just built using docker
# They generate a timestamp file in $(BUILDDIR)
$(TOOLCHAINS_DOC_TS): $(BUILDDIR)/%: %/Dockerfile | $(BUILDDIR)/toolchains
	@echo "Building $*"
	docker build -t $* -f $< $(<D)
	touch "$@"

# m4 Dockerfile toolchains are preprocessed using GNU m4 before being built by docker
# m4 include path is toolchains/m4 and directory of the toolchain
# toolchains/m4/library.m4 is automatically included at start for common functions
# Using VERBOSE=1 makes rule generate a Dockerfile.debug file with preprocessed content and optional trace (m4_traceon instruction)
# They generate a timestamp file in $(BUILDDIR)
$(TOOLCHAINS_M4_TS): $(BUILDDIR)/%: %/Dockerfile.m4 | $(BUILDDIR)/toolchains
	@echo "Building $*"
ifeq ($(VERBOSE),1)
	$(call m4_cmdline,$(<D),$<,$(M4_DEBUG)) > $(<D)/Dockerfile.debug 2>&1
endif
	$(call m4_cmdline,$(<D),$<) | \
		docker build -t $* -f - $(<D)
	touch "$@"

# Non-built toolchains are downloaded using previously defined recipe
# They generate a timestamp file in $(BUILDDIR)
# As it's a PHONY rule, don't make it a dependency but invoke it
$(TOOLCHAINS_DL_TS): $(BUILDDIR)/%:
	@$(MAKE) $*/pull

# Specific toolchains interdependencies
$(eval $(call DEPEND_IMAGE,\
	toolchains/android,\
	toolchains/android-common,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/android-old,\
	toolchains/android-common,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/devkit3ds,\
	toolchains/devkitarm,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/devkitnds,\
	toolchains/devkitarm,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/macosx-arm64,\
	toolchains/macosx-common,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/macosx-arm64,\
	toolchains/apple-sdks,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/macosx-x86_64,\
	toolchains/macosx-common,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/macosx-x86_64,\
	toolchains/apple-sdks,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/macosx-i386,\
	toolchains/macosx-common,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/macosx-i386,\
	toolchains/apple-sdks,\
	$(TOOLCHAINS_BUILT)))
$(eval $(call DEPEND_IMAGE,\
	toolchains/iphone,\
	toolchains/apple-sdks,\
	$(TOOLCHAINS_BUILT)))

# Generate dependencies over files and to common toolchain only for toolchains we will build
$(foreach i,$(TOOLCHAINS_BUILT), \
	$(eval $(call MAKE_DEPS,$(i))) \
)
$(foreach i,$(TOOLCHAINS_BUILT), \
	$(eval $(call DEPEND_COMMON,$(i))) \
)

# Workers rules
# List all workers: m4 based and raw Dockerfile based
ALL_WORKERS_M4  := $(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile.m4)))
ALL_WORKERS_DOC := $(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile)))
ALL_WORKERS     := $(ALL_WORKERS_M4) $(ALL_WORKERS_DOC)

WORKERS_RESTRICTED := workers/macosx-arm64 workers/macosx-x86_64 workers/macosx-i386 workers/iphone

# Override because we use the provided value and calculate the real one
override WORKERS_ENABLED := $(call filter_list,$(WORKERS_ENABLED),$(ALL_WORKERS),workers/)
override WORKERS_BUILT   := $(call filter_list,$(WORKERS_BUILT),$(WORKERS_ENABLED),workers/)
ifeq ($(DOCKER_PRIVATE),1)
	WORKERS_ONLINE   := $(WORKERS_ENABLED)
else
	WORKERS_ONLINE   := $(filter-out $(WORKERS_RESTRICTED),$(WORKERS_ENABLED))
endif
WORKERS_DOWNLOADED       := $(filter-out $(WORKERS_BUILT),$(WORKERS_ONLINE))

# Build timestamps files generated as a marker
WORKERS_M4_TS  := $(foreach i,$(filter $(WORKERS_BUILT),$(ALL_WORKERS_M4)),$(BUILDDIR)/$(i))
WORKERS_DOC_TS := $(foreach i,$(filter $(WORKERS_BUILT),$(ALL_WORKERS_DOC)),$(BUILDDIR)/$(i))
WORKERS_DL_TS  := $(foreach i,$(WORKERS_DOWNLOADED),$(BUILDDIR)/$(i))
WORKERS_TS     := $(WORKERS_M4_TS) $(WORKERS_DOC_TS) $(WORKERS_DL_TS)

# Build clean/push/pull rules
WORKERS_CLEAN := $(foreach i,$(WORKERS_ENABLED),$(i)/clean)
WORKERS_PUSH  := $(foreach i,$(WORKERS_ONLINE),$(i)/push)
WORKERS_PULL  := $(foreach i,$(WORKERS_ONLINE),$(i)/pull)

# Phony rules to manage all workers easily
workers      : $(WORKERS_ENABLED)
clean-workers: $(WORKERS_CLEAN)
push-workers : $(WORKERS_PUSH)
pull-workers : $(WORKERS_PULL)

# Phony rule to build one worker
$(WORKERS_ENABLED): %: $(BUILDDIR)/%

# Phony rule to clean workers
$(WORKERS_CLEAN): %/clean:
	docker rmi -f $*
	rm -f $(BUILDDIR)/$*

# Phony rules to push and pull images from registry
$(WORKERS_PUSH): %/push: $(BUILDDIR)/%
	docker tag $* $(call build_docker_url,$*) && \
		docker push $(call build_docker_url,$*) && \
		docker rmi $(call build_docker_url,$*)

# Update timestamp to avoid building image if we got it
# Remove repository tag as it's duplicated
$(WORKERS_PULL): %/pull: | $(BUILDDIR)/workers
	docker pull $(call build_docker_url,$*) && \
		docker tag $(call build_docker_url,$*) $* && \
		docker rmi $(call build_docker_url,$*) && \
		touch -d `docker inspect -f '{{ .Created }}' $*` $(BUILDDIR)/$*

.PHONY: workers push-workers pull-workers clean-workers \
	$(WORKERS_ENABLED) $(WORKERS_CLEAN) $(WORKERS_PUSH) $(WORKERS_PULL)

# Raw Dockerfile workers are just built using docker
# They generate a timestamp file in $(BUILDDIR)
$(WORKERS_DOC_TS): $(BUILDDIR)/%: %/Dockerfile | $(BUILDDIR)/workers
	@echo "Building $*"
	docker build --build-arg BUILDBOT_VERSION=$(BUILDBOT_VERSION) -t $* -f $< $(<D)
	touch "$@"

# m4 Dockerfile workers are preprocessed using GNU m4 before being built by docker
# m4 include path is workers/m4 and directory of the worker
# workers/m4/library.m4 is automatically included at start for common functions
# Using VERBOSE=1 makes rule generate a Dockerfile.debug file with preprocessed content and optional trace (m4_traceon instruction)
# They generate a timestamp file in $(BUILDDIR)
$(WORKERS_M4_TS): $(BUILDDIR)/%: %/Dockerfile.m4 | $(BUILDDIR)/workers
	@echo "Building $*"
ifeq ($(VERBOSE),1)
	$(call m4_cmdline,$(<D),$<,$(M4_DEBUG)) > $(<D)/Dockerfile.debug 2>&1
endif
	$(call m4_cmdline,$(<D),$<) | \
		docker build --build-arg BUILDBOT_VERSION=$(BUILDBOT_VERSION) -t $* -f - $(<D)
	touch "$@"

# Non-built workers are downloaded using previously defined recipe
# They generate a timestamp file in $(BUILDDIR)
# As it's a PHONY rule, don't make it a dependency but invoke it
$(WORKERS_DL_TS): $(BUILDDIR)/%:
	@$(MAKE) $*/pull

# Generate dependencies over files and to toolchain of the same name only for workers we will build
$(foreach i,$(WORKERS_BUILT), \
	$(eval $(call MAKE_DEPS,$(i))) \
)
$(foreach i,$(WORKERS_BUILT), \
	$(eval $(call DEPEND_TOOLCHAIN,$(i))) \
)
# Generate dependencies on Makefile as it defines BUILDBOT_VERSION
$(foreach i,$(WORKERS_BUILT), \
	$(eval $(call DEPEND_MAKEFILE,$(i))) \
)
