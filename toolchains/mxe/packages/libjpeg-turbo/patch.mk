# Patch libjpeg-turbo_BUILD to install libjpeg-turbo in the correct place in the prefix
# newline variable is defined by MXE
$(eval define libjpeg-turbo_BUILD$(newline)\
  $(subst /$$(PKG),,$(value libjpeg-turbo_BUILD))$(newline)\
endef)
