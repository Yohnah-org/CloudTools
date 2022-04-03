CURRENT_VERSION := $(subst ", ,$(shell curl -sS "https://app.vagrantup.com/api/v1/box/Yohnah/CloudTools" | jq '.current_version.version'))
CURRENT_MAJOR_VERSION := $(word 1,$(subst ., ,$(CURRENT_VERSION)))
CURRENT_MINOR_VERSION := $(word 2,$(subst ., ,$(CURRENT_VERSION)))
CURRENT_PATH_VERSION := $(word 3,$(subst ., ,$(CURRENT_VERSION)))
CURRENT_DEBIAN_VERSION := $(shell curl -s https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ | grep -oE "debian-(.*)-amd64-netinst.iso" | sed -e 's/<[^>]*>//g' | cut -d">" -f 1 | sed 's/"//g' | head -n 1 | cut -d- -f2)
NEW_VERSION := $(or $(NEW_VERSION),$(CURRENT_MAJOR_VERSION).$(CURRENT_MINOR_VERSION).$(shell expr $(CURRENT_PATH_VERSION) + 1))
OUTPUT_DIRECTORY := /tmp
DATETIME := $(shell date "+%Y-%m-%d %H:%M:%S")

.PHONY: all version build clean_test test upload clean

all: version build test upload clean

version:
	@echo "========================="
	@echo Current version: $(CURRENT_MAJOR_VERSION).$(CURRENT_MINOR_VERSION).$(CURRENT_PATH_VERSION)
	@echo New proposed version: $(NEW_VERSION)
	@echo "========================="
	@echo ""

build: 
	cd Packer; packer build -var "output_directory=$(OUTPUT_DIRECTORY)" -var "debian_version=$(CURRENT_DEBIAN_VERSION)" packer.pkr.hcl

test:
	vagrant box add --name "testing-cloudtools-box" $(OUTPUT_DIRECTORY)/packer-build/output/boxes/cloudtools/virtualbox/cloudtools.box
	mkdir -p $(OUTPUT_DIRECTORY)/vagrant-cloudtools-test; cd $(OUTPUT_DIRECTORY)/vagrant-cloudtools-test; vagrant init testing-cloudtools-box; \
	vagrant up --provider virtualbox; \
	vagrant ssh -c "ls /"; \
	vagrant destroy -f

clean_test:
	vagrant box remove testing-cloudtools-box || true
	rm -fr $(OUTPUT_DIRECTORY)/vagrant-cloudtools-test

upload:
	cd Packer; packer build -var "input_directory=$(OUTPUT_DIRECTORY)" -var "version=$(NEW_VERSION)" -var "version_description=$(DATETIME)" upload-box-to-vagrant-cloud.pkr.hcl

clean: clean_test
	rm -fr $(OUTPUT_DIRECTORY)/packer-build
