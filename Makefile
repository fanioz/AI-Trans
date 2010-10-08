-include Makefile.local

FILENAME       := Trans_AI

shell          ?= /bin/sh
HG             ?= hg
REPO_DATE       = $(shell $(HG) parent --template="{date|shortdate}")
VERSION        := $(shell date -d $(REPO_DATE) +%y%m%d)
OSTYPE         := $(shell uname -s)
BUNDLE_NAME    := $(FILENAME)-$(VERSION)
TAR_FILENAME   := $(BUNDLE_NAME).tar

_E             := @echo
_V             := @

ifeq ($(OSTYPE),Linux)
INSTALL_DIR?=$(HOME)/.openttd/ai
else
ifeq ($(OSTYPE),Darwin)
INSTALL_DIR?=$(HOME)/Documents/OpenTTD/ai
else
ifeq ($(shell echo "$(OSTYPE)" | cut -d_ -f1),MINGW32)
INSTALL_DIR?="$(ALLUSERSPROFILE)\Documents\OpenTTD\ai"
else
INSTALL_DIR?=
endif
endif
endif

all: bundle_tar

bundle_tar: clean
	$(_E) "[TAR]"
	$(_V) $(shell $(HG) archive -X glob:.* $(BUNDLE_NAME))
	$(_V) cat info.nut | sed -e "s/return 150101/return $(VERSION)/g" > $(BUNDLE_NAME)/info.nut
	$(_V) tar -cf $(TAR_FILENAME) $(BUNDLE_NAME)

clean:
	$(_E) "[Clean]"
	$(_V) -rm -r -f $(BUNDLE_NAME)
	$(_V) -rm -r -f $(TAR_FILENAME)
	
# Installation process
install: all
	$(_E) "[INSTALL] to $(INSTALL_DIR)"
	$(_V) install -d $(INSTALL_DIR)
	$(_V) install -m644 $(TAR_FILENAME) $(INSTALL_DIR)
	
test:
	$(_E) "HG:                           $(HG)"
	$(_E) "OS-Type:                      $(OSTYPE)"
	$(_E) "Repo Date:                    $(REPO_DATE)"
	$(_E) "Installation directory:       $(INSTALL_DIR)"
	$(_E) "AI Version:                   $(VERSION)"
	$(_E) "Build folder:                 $(BUNDLE_NAME)"
	$(_E) "Bundle filenames       tar:   $(TAR_FILENAME)"

help:
	$(_E) ""
	$(_E) "$(FILENAME) version $(VERSION) Makefile"
	$(_E) "Usage : make [option]"
	$(_E) ""
	$(_E) "options:"
	$(_E) "  all           bundle the files"
	$(_E) "  clean         remove the files generated during bundling"
	$(_E) "  install       install AI into $(INSTALL_DIR)"
	$(_E) "  bundle_tar    create bundle $(TAR_FILENAME)"
	$(_E) "  test          test to see the value of environment"
	$(_E) ""
		
.PHONY: all test clean help

