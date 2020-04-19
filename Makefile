BUILDBOT_VERSION=2.7.0

VERBOSE = 
BUILDDIR = .build
M4_DEBUG = -dcxaeq

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

# All these targets are directories that should be made
$(BUILDDIR) $(BUILDDIR)/toolchains $(BUILDDIR)/workers: %:
	mkdir -p $@

# Debug informations
status:
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
.PHONY: master

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
TOOLCHAINS_M4=$(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile.m4)))
TOOLCHAINS_DOC=$(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile)))
TOOLCHAINS=$(TOOLCHAINS_M4) $(TOOLCHAINS_DOC)

# Build timestamps files generated as a marker
TOOLCHAINS_M4_TS=$(foreach i,$(TOOLCHAINS_M4),$(BUILDDIR)/$(i))
TOOLCHAINS_DOC_TS=$(foreach i,$(TOOLCHAINS_DOC),$(BUILDDIR)/$(i))
TOOLCHAINS_TS=$(TOOLCHAINS_M4_TS) $(TOOLCHAINS_DOC_TS)

# Phony rules to build and clean toolchains easily
toolchains: $(TOOLCHAINS)
clean-toolchains:
	docker rmi $(TOOLCHAINS)
	rm -f $(TOOLCHAINS_TS)

$(TOOLCHAINS): %: $(BUILDDIR)/%
.PHONY: toolchains clean-toolchains $(TOOLCHAINS)

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
WORKERS_M4=$(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile.m4)))
WORKERS_DOC=$(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile)))
WORKERS=$(WORKERS_M4) $(WORKERS_DOC)

# Build timestamps files generated as a marker
WORKERS_M4_TS=$(foreach i,$(WORKERS_M4),$(BUILDDIR)/$(i))
WORKERS_DOC_TS=$(foreach i,$(WORKERS_DOC),$(BUILDDIR)/$(i))
WORKERS_TS=$(WORKERS_M4_TS) $(WORKERS_DOC_TS)

# Phony rules to build and clean workers easily
workers: $(WORKERS)
clean-workers:
	docker rmi $(WORKERS)
	rm -f $(WORKERS_TS)

$(WORKERS): %: $(BUILDDIR)/%
.PHONY: workers $(WORKERS) clean-workers

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
