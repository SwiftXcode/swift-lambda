# Makefile
# Copyright © 2018-2020 ZeeZide GmbH. All rights reserved.

ifeq ($(prefix),)
  prefix=/usr/local
endif

STATIC_LIBRARY_PREFIX=lib
STATIC_LIBRARY_SUFFIX=.a

MKDIR_P     = mkdir -p
INSTALL     = cp
INSTALL_R   = cp -r
UNINSTALL   = rm -f
UNINSTALL_R = rm -rf
XML_LINTER  = xmllint >/dev/null

# Darwin, x86_64
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
else
  $(error "only makes sense on Darwin ;-)")
endif

PLATFORM_PREFERRED_ARCH = $(shell uname -m)
CURRENT_ARCH            = $(PLATFORM_PREFERRED_ARCH)

# System specific configuration

ifeq ($(UNAME_S),Darwin)
  PLATFORM_NAME=$(shell sw_vers -productName | sed "s/ //g" | tr '[:upper:]' '[:lower:]')
  SWIFT_PLATFORM_TARGET_PREFIX=$(PLATFORM_NAME)
  DEPLOYMENT_TARGET_SETTING_NAME=MACOSX_DEPLOYMENT_TARGET
  
  MACOS_VERSION=$(shell sw_vers -productVersion)
  MACOS_VERSION_LIST=$(subst ., ,$(MACOS_VERSION))
  MACOS_MAJOR=$(word 1,$(MACOS_VERSION_LIST))
  MACOS_MINOR=$(word 2,$(MACOS_VERSION_LIST))
  MACOS_SUBMINOR_OPT=$(word 3,$(MACOS_VERSION_LIST))
  MACOS_SUBMINOR=$(if $(MACOS_SUBMINOR_OPT),$(MACOS_SUBMINOR_OPT),0)
  MACOSX_DEPLOYMENT_TARGET=$(MACOS_MAJOR).$(MACOS_MINOR)
  
  SWIFT_TOOLCHAIN_BASEDIR=/Library/Developer/Toolchains
  #SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/swift-latest.xctoolchain/usr/bin
  ifeq ("$(wildcard $(SWIFT_TOOLCHAIN))","")
    SWIFTC=$(shell xcrun --toolchain swift-latest -f swiftc)
    SWIFT_TOOLCHAIN=$(dir $(shell xcrun --toolchain swift-latest -f swiftc))
    SWIFT=$(SWIFT_TOOLCHAIN)/swift
  else
    SWIFT=swift
    SWIFTC=swiftc
  endif
  
  SWIFT_TOOLCHAIN_LIB_DIR=$(subst /usr/bin,/usr/lib/swift/$(PLATFORM_NAME),$(SWIFT_TOOLCHAIN))
  
  DEFAULT_SDK=$(shell xcrun -sdk macosx --show-sdk-path)
else # Linux
  PLATFORM_NAME=$(shell echo $(UNAME_S) | tr '[:upper:]' '[:lower:]')
  SWIFT=swift
  SWIFTC=swiftc
endif

TARGET = $(CURRENT_ARCH)-apple-$(SWIFT_PLATFORM_TARGET_PREFIX)$($(DEPLOYMENT_TARGET_SETTING_NAME))


# Swift

SWIFT_VERSION=$(shell $(SWIFT) --version | head -1 | sed 's/^.*[Vv]ersion[\t ]*\([.[:digit:]]*\).*$$/\1/g')
SWIFT_VERSION_LIST=$(subst ., ,$(SWIFT_VERSION))
SWIFT_MAJOR=$(word 1,$(SWIFT_VERSION_LIST))
SWIFT_MINOR=$(word 2,$(SWIFT_VERSION_LIST))
SWIFT_SUBMINOR_OPT=$(word 3,$(SWIFT_VERSION_LIST))
SWIFT_SUBMINOR=$(if $(SWIFT_SUBMINOR_OPT),$(SWIFT_SUBMINOR_OPT),0)

SWIFT_BUILD_DIR = $(PWD)/.build


# OK, here we assume that major.minor is ABI stable. Which I think may be
# reasonable ;->
# If it turns out to be different, we can still patch this.
SWIFT_ABI_RELDIR=swift$(SWIFT_MAJOR).$(SWIFT_MINOR)


# We have set prefix above, or we got it via ./config.make
# Now we need to derive:
# - BINARY_INSTALL_DIR            e.g. /usr/bin

ifeq ($(BINARY_INSTALL_DIR),)
  BINARY_INSTALL_DIR=$(prefix)/bin
endif

ifeq ($(UNAME_S),Darwin)
  ifeq ($(SWIFT_ABI_LIB_INSTALL_DIR),)
    # macOS seems to use this for modmaps: /usr/lib/swift/macosx/x86_64/
    # and this for the dylibs: /usr/lib/swift/macosx/
    # FIXME: we changed this to the TARGET, needs to be:
    #   /usr/local/lib/swift4.0/x86_64-apple-macosx10.13
    # and we need to allow configuration on what we build for.
    SWIFT_ABI_LIB_INSTALL_DIR=$(prefix)/lib/$(SWIFT_ABI_RELDIR)/$(TARGET)
  endif
    
  XCODE_DIR=/Applications/Xcode.app
  XCODE_PLATFORMS_RELDIR=Contents/Developer/Platforms
endif
