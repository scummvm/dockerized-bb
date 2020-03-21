BUILDBOT_VERSION=2.7.0

VERBOSE = 
BUILDDIR = .build

nothing:

# Helpers

define MAKE_DEPS
$(BUILDDIR)/$(1): $(shell find $(1)/ -type f) | $(BUILDDIR)/$(patsubst %/,%,$(dir $(1)))
endef
define DEPEND_COMMON
$(BUILDDIR)/$(1): $(if $(findstring /common,$(1)),,$(BUILDDIR)/$(dir $(1))common)
endef
define DEPEND_TOOLCHAIN
$(BUILDDIR)/$(1): $(if $(wildcard toolchains/$(notdir $(1))),$(BUILDDIR)/toolchains/$(notdir $(1)))
endef

$(BUILDDIR) $(BUILDDIR)/toolchains $(BUILDDIR)/workers: %:
	mkdir -p $@

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

ccache-stats:
	@CCACHE_DIR=buildbot-data/ccache ccache -s

# Master rules

master: $(BUILDDIR)/buildbot_installed master/buildbot.tac

$(BUILDDIR)/buildbot_installed: Makefile | $(BUILDDIR)
	pip install 'buildbot[bundle]==$(BUILDBOT_VERSION)'
	touch $(BUILDDIR)/buildbot_installed

master/buildbot.tac: $(BUILDDIR)/buildbot_installed
	buildbot create-master -rf master
	rm master/master.cfg.sample
	touch master/buildbot.tac

# Toolchains rules
TOOLCHAINS_M4=$(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile.m4)))
TOOLCHAINS_DOC=$(patsubst %/,%,$(dir $(wildcard toolchains/*/Dockerfile)))
TOOLCHAINS=$(TOOLCHAINS_M4) $(TOOLCHAINS_DOC)

TOOLCHAINS_M4_TS=$(foreach i,$(TOOLCHAINS_M4),$(BUILDDIR)/$(i))
TOOLCHAINS_DOC_TS=$(foreach i,$(TOOLCHAINS_DOC),$(BUILDDIR)/$(i))
TOOLCHAINS_TS=$(TOOLCHAINS_M4_TS) $(TOOLCHAINS_DOC_TS)

toolchains: $(TOOLCHAINS)
$(TOOLCHAINS): %: $(BUILDDIR)/%

$(TOOLCHAINS_DOC_TS): $(BUILDDIR)/%: %/Dockerfile
	@echo "Building $*"
	docker build -t $* -f $< $(<D)
	touch "$@"

$(TOOLCHAINS_M4_TS): $(BUILDDIR)/%: %/Dockerfile.m4 $(shell find toolchains/m4 -type f)
	@echo "Building $*"
ifeq ($(VERBOSE),1)
	m4 -P -EE -I toolchains/m4 toolchains/m4/library.m4 $< > $(<D)/Dockerfile.debug
endif
	m4 -P -EE -I toolchains/m4 toolchains/m4/library.m4 $< | \
		docker build -t $* -f - $(<D)
	touch "$@"

$(foreach i,$(TOOLCHAINS),$(eval $(call MAKE_DEPS,$(i))))
$(foreach i,$(TOOLCHAINS),$(eval $(call DEPEND_COMMON,$(i))))

# Add here all dependencies between toolchains
$(BUILDDIR)/toolchains/devkitnds: $(BUILDDIR)/toolchains/devkitarm

clean-toolchains:
	docker rmi $(TOOLCHAINS)
	rm -f $(TOOLCHAINS_TS)

# Workers rules
WORKERS_M4=$(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile.m4)))
WORKERS_DOC=$(patsubst %/,%,$(dir $(wildcard workers/*/Dockerfile)))
WORKERS=$(WORKERS_M4) $(WORKERS_DOC)

WORKERS_M4_TS=$(foreach i,$(WORKERS_M4),$(BUILDDIR)/$(i))
WORKERS_DOC_TS=$(foreach i,$(WORKERS_DOC),$(BUILDDIR)/$(i))
WORKERS_TS=$(WORKERS_M4_TS) $(WORKERS_DOC_TS)

workers: $(WORKERS)
$(WORKERS): %: $(BUILDDIR)/%

$(WORKERS_DOC_TS): $(BUILDDIR)/%: %/Dockerfile
	@echo "Building $*"
	docker build --build-arg BUILDBOT_VERSION=$(BUILDBOT_VERSION) -t $@ -f $< $(<D)
	touch "$@"

$(WORKERS_M4_TS): $(BUILDDIR)/%: %/Dockerfile.m4 $(shell find workers/m4 -type f)
	@echo "Building $*"
ifeq ($(VERBOSE),1)
	m4 -P -EE -I workers/m4 workers/m4/library.m4 $< -o $(<D)/Dockerfile.debug
endif
	m4 -P -EE -I workers/m4 workers/m4/library.m4 $< | \
		docker build --build-arg BUILDBOT_VERSION=$(BUILDBOT_VERSION) -t $* -f - $(<D)
	touch "$@"

$(foreach i,$(WORKERS),$(eval $(call MAKE_DEPS,$(i))))
$(foreach i,$(WORKERS),$(eval $(call DEPEND_TOOLCHAIN,$(i))))

clean-workers:
	docker rmi $(WORKERS)
	rm -f $(WORKERS_TS)

.PHONY: nothing master status toolchains $(TOOLCHAINS) clean-toolchains workers $(WORKERS) clean-workers ccache-stats
