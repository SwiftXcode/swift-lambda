# Makefile
# Copyright 2017-2020 ZeeZide GmbH. All rights reserved.

include swift-lambda-config.make

SCRIPTS = $(wildcard scripts/swift-lambda*)

all :

clean :

distclean : clean

install : all install-scripts

uninstall : uninstall-scripts


# scripts

install-scripts:
	$(MKDIR_P) $(BINARY_INSTALL_DIR)
	$(INSTALL) $(SCRIPTS) $(BINARY_INSTALL_DIR)/

uninstall-scripts:
	$(UNINSTALL) $(addprefix $(BINARY_INSTALL_DIR)/,$(notdir $(SCRIPTS)))
