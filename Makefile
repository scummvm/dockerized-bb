BUILDBOT_VERSION := 2.7.0
DOCKER_REGISTRY := lephilousophe/scummvm
DOCKER_SEPARATOR := :

VERBOSE := 0
BUILDDIR := .build
M4_DEBUG := -dcxaeq

# To let user override previous values easily
# User can also set values on command line
-include Makefile.user

# Helpers

# Create dependencies list based on docker context contents
define MAKE_DEPS
$(BUILDDIR)/$(1): $(shell find $(1)/ -type f) | $(BUILDDIR)/$(patsubst %/,%,$(dir $(1)))
endef
# Create a dependency on common (used by toolchains) except when target is common
define DEPEND_COMMON
$(BUILDDIR)/$(1): \
	$(if $(filter-out common,$(notdir $(1))), \
		$(BUILDDIR)/$(dir $(1))common \
	)
endef
# Create a dependency on the toolchain of same name if it exists (used by workers)
define DEPEND_TOOLCHAIN
$(BUILDDIR)/$(1): \
	$(if $(wildcard toolchains/$(notdir $(1))), \
		$(BUILDDIR)/toolchains/$(notdir $(1)) \
	)
endef
# Return the docker URL with path sanitized
build_docker_url = $(DOCKER_REGISTRY)$(DOCKER_SEPARATOR)$(subst /,.,$(1))

# All these targets are directories that should be made
$(BUILDDIR) $(BUILDDIR)/toolchains $(BUILDDIR)/workers: %:
	mkdir -p $@

# Debug informations
status:
	@echo "Buildbot version: " $(BUILDBOT_VERSION)
	@echo "Timestamps directory: " $(BUILDDIR)
	@echo "Toolchains to preprocess: " $(TOOLCHAINS_M4)
	@echo "Toolchains without preprocessing: " $(TOOLCHAINS_DOC)
	@echo "All toolchains: " $(TOOLCHAINS)
	@echo "Toolchains timestamps: " $(TOOLCHAINS_TS)
	@echo "Workers to preprocess: " $(WORKERS_M4)
	@echo "Workers without preprocessing: " $(WORKERS_DOC)
	@echo "All workers: " $(WORKERS)
	@echo "Workers timestamps: " $(WORKERS_TS)

# Debug ccache used by workers
ccache-stats:
	@CCACHE_DIR=buildbot-data/ccache ccache -s
.PHONY: status ccache-stats

# Master rules

# Prerequisites are quite redundant but that makes no harm
master: $(BUILDDIR)/buildbot_installed master/buildbot.tac

# Shortcut to check if config OK for buildbot
# That avoids any downtime at restart if it was bad
master-check: master/buildbot.tac
	cd master && \
		buildbot checkconfig

.PHONY: master master-check

# buildbot depend on Makefile as we modify version here
$(BUILDDIR)/buildbot_installed: Makefile | $(BUILDDIR)
	pip install 'buildbot[bundle]==$(BUILDBOT_VERSION)'
	touch $(BUILDDIR)/buildbot_installed

# Create startup file once buildbot is installed and up-to-date
# Database setting is loaded from master/config.py
# create-master with initialize the database if it doesn't exist yet
# upgrade-master will upgrade it if it needs to be
master/buildbot.tac: $(BUILDDIR)/buildbot_installed
	DBLINE=$$(cd master && python3 -c 'import config; config.init("."); print(config.db["db_url"])') && \
		buildbot create-master -rf --db=$${DBLINE} master
	buildbot upgrade-master master
	rm master/master.cfg.sample
	touch master/buildbot.tac

# Toolchains rules
# List all toolchains: m4 based and raw Dockerfile based
TOOLCHAINS_M4 := $(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile.m4)))
TOOLCHAINS_DOC := $(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile)))
TOOLCHAINS := $(TOOLCHAINS_M4) $(TOOLCHAINS_DOC)

# Build timestamps files generated as a marker
TOOLCHAINS_M4_TS := $(foreach i,$(TOOLCHAINS_M4),$(BUILDDIR)/$(i))
TOOLCHAINS_DOC_TS := $(foreach i,$(TOOLCHAINS_DOC),$(BUILDDIR)/$(i))
TOOLCHAINS_TS := $(TOOLCHAINS_M4_TS) $(TOOLCHAINS_DOC_TS)

# Build clean/push/pull rules
TOOLCHAINS_CLEAN := $(foreach i,$(TOOLCHAINS),$(i)/clean)
TOOLCHAINS_PUSH := $(foreach i,$(TOOLCHAINS),$(i)/push)
TOOLCHAINS_PULL := $(foreach i,$(TOOLCHAINS),$(i)/pull)

# Phony rules to manage all toolchains easily
toolchains: $(TOOLCHAINS)
clean-toolchains: $(TOOLCHAINS_CLEAN)
push-toolchains: $(TOOLCHAINS_PUSH)
pull-toolchains: $(TOOLCHAINS_PULL)

$(TOOLCHAINS): %: $(BUILDDIR)/%

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
$(TOOLCHAINS_PULL): %/pull:
	docker pull $(call build_docker_url,$*) && \
		docker tag $(call build_docker_url,$*) $* && \
		docker rmi $(call build_docker_url,$*) && \
		touch -d `docker inspect -f '{{ .Created }}' $*` $(BUILDDIR)/$*

.PHONY: toolchains push-toolchains pull-toolchains clean-toolchains \
	$(TOOLCHAINS) $(TOOLCHAINS_CLEAN) $(TOOLCHAINS_PUSH) $(TOOLCHAINS_PULL)

# Raw Dockerfile toolchains are just built using docker
# They generate a timestamp file in $(BUILDDIR)
$(TOOLCHAINS_DOC_TS): $(BUILDDIR)/%: %/Dockerfile
	@echo "Building $*"
	docker build -t $* -f $< $(<D)
	touch "$@"

# m4 Dockerfile toolchains are preprocessed using GNU m4 before being built by docker
# m4 include path is toolchains/m4 and directory of the toolchain
# toolchains/m4/library.m4 is automatically included at start for common functions
# Using VERBOSE=1 makes rule generate a Dockerfile.debug file with preprocessed content and optional trace (m4_traceon instruction)
# They generate a timestamp file in $(BUILDDIR)
$(TOOLCHAINS_M4_TS): $(BUILDDIR)/%: %/Dockerfile.m4 $(shell find toolchains/m4 -type f)
	@echo "Building $*"
ifeq ($(VERBOSE),1)
	m4 -P -EE $(M4_DEBUG) -I toolchains/m4 -I $(<D) toolchains/m4/library.m4 $< > $(<D)/Dockerfile.debug 2>&1
endif
	m4 -P -EE -I toolchains/m4 -I $(<D) toolchains/m4/library.m4 $< | \
		docker build -t $* -f - $(<D)
	touch "$@"

# Specific toolchains interdependencies
$(BUILDDIR)/toolchains/android: $(BUILDDIR)/toolchains/android-common
$(BUILDDIR)/toolchains/android-old: $(BUILDDIR)/toolchains/android-common
$(BUILDDIR)/toolchains/devkit3ds: $(BUILDDIR)/toolchains/devkitarm
$(BUILDDIR)/toolchains/devkitnds: $(BUILDDIR)/toolchains/devkitarm

# Generate dependencies over files and common toolchain
$(foreach i,$(TOOLCHAINS), \
	$(eval $(call MAKE_DEPS,$(i))) \
)
$(foreach i,$(TOOLCHAINS), \
	$(eval $(call DEPEND_COMMON,$(i))) \
)

# Workers rules
# List all workers: m4 based and raw Dockerfile based
WORKERS_M4 := $(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile.m4)))
WORKERS_DOC := $(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile)))
WORKERS := $(WORKERS_M4) $(WORKERS_DOC)

# Build timestamps files generated as a marker
WORKERS_M4_TS := $(foreach i,$(WORKERS_M4),$(BUILDDIR)/$(i))
WORKERS_DOC_TS := $(foreach i,$(WORKERS_DOC),$(BUILDDIR)/$(i))
WORKERS_TS := $(WORKERS_M4_TS) $(WORKERS_DOC_TS)

# Build clean/push/pull rules
WORKERS_CLEAN := $(foreach i,$(WORKERS),$(i)/clean)
WORKERS_PUSH := $(foreach i,$(WORKERS),$(i)/push)
WORKERS_PULL := $(foreach i,$(WORKERS),$(i)/pull)

# Phony rules to manage all workers easily
workers: $(WORKERS)
clean-workers: $(WORKERS_CLEAN)
push-workers: $(WORKERS_PUSH)
pull-workers: $(WORKERS_PULL)

$(WORKERS): %: $(BUILDDIR)/%

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
$(WORKERS_PULL): %/pull:
	docker pull $(call build_docker_url,$*) && \
		docker tag $(call build_docker_url,$*) $* && \
		docker rmi $(call build_docker_url,$*) && \
		touch -d `docker inspect -f '{{ .Created }}' $*` $(BUILDDIR)/$*

.PHONY: workers push-workers pull-workers clean-workers \
	$(WORKERS) $(WORKERS_CLEAN) $(WORKERS_PUSH) $(WORKERS_PULL)

# Raw Dockerfile workers are just built using docker
# They generate a timestamp file in $(BUILDDIR)
$(WORKERS_DOC_TS): $(BUILDDIR)/%: %/Dockerfile
	@echo "Building $*"
	docker build --build-arg BUILDBOT_VERSION=$(BUILDBOT_VERSION) -t $@ -f $< $(<D)
	touch "$@"

# m4 Dockerfile workers are preprocessed using GNU m4 before being built by docker
# m4 include path is workers/m4 and directory of the worker
# workers/m4/library.m4 is automatically included at start for common functions
# Using VERBOSE=1 makes rule generate a Dockerfile.debug file with preprocessed content and optional trace (m4_traceon instruction)
# They generate a timestamp file in $(BUILDDIR)
$(WORKERS_M4_TS): $(BUILDDIR)/%: %/Dockerfile.m4 $(shell find workers/m4 -type f)
	@echo "Building $*"
ifeq ($(VERBOSE),1)
	m4 -P -EE $(M4_DEBUG) -I workers/m4 -I $(<D) workers/m4/library.m4 $< > $(<D)/Dockerfile.debug 2>&1
endif
	m4 -P -EE -I workers/m4 -I $(<D) workers/m4/library.m4 $< | \
		docker build --build-arg BUILDBOT_VERSION=$(BUILDBOT_VERSION) -t $* -f - $(<D)
	touch "$@"

# Generate dependencies over files and toolchain of the same name
$(foreach i,$(WORKERS), \
	$(eval $(call MAKE_DEPS,$(i))) \
)
$(foreach i,$(WORKERS), \
	$(eval $(call DEPEND_TOOLCHAIN,$(i))) \
)
