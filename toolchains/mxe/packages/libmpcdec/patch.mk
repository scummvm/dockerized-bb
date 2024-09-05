# Patch libmpcdec_BUILD to install libmpcdec.a without a _static suffix
# Also remove useless LDFLAGS once the attached patch is applied
# newline and comma variables are defined by MXE
$(eval define libmpcdec_BUILD$(newline)\
  $(subst libmpcdec_static.a' '$$(PREFIX)/$$(TARGET)/lib/',libmpcdec_static.a' '$$(PREFIX)/$$(TARGET)/lib/libmpcdec.a',$(value libmpcdec_BUILD))$(newline)\
  $(subst LDFLAGS='$$(LDFLAGS) -Wl$(comma)--allow-multiple-definition',,$(value libmpcdec_BUILD))$(newline)\
endef)
