variable "output_directory" {
    type = string
    default = "."
}

locals {
    vm_name = "cloudtools"
    debian_version = "11.2.0"
    http_directory = "${path.root}/http"
    iso_url = "https://cdimage.debian.org/debian-cd/${local.debian_version}/amd64/iso-cd/debian-${local.debian_version}-amd64-netinst.iso"
    iso_checksum = "file:https://cdimage.debian.org/debian-cd/${local.debian_version}/amd64/iso-cd/SHA256SUMS"
    shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
    boot_command = [
        "<esc><wait10s>",
        "install <wait>",
        "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
        "debian-installer=en_US.UTF-8 <wait>",
        "auto <wait>",
        "locale=en_US.UTF-8 <wait>",
        "kbd-chooser/method=us <wait>",
        "keyboard-configuration/xkb-keymap=us <wait>",
        "netcfg/get_hostname={{ .Name }} <wait>",
        "netcfg/get_domain=vagrantup.com <wait>",
        "fb=false <wait>",
        "debconf/frontend=noninteractive <wait>",
        "console-setup/ask_detect=false <wait>",
        "console-keymaps-at/keymap=us <wait>",
        "grub-installer/bootdev=/dev/sda <wait>",
        "<enter><wait>"    
    ]
}

source "virtualbox-iso" "cloudtools" {
    boot_command = local.boot_command
    boot_wait = "6s"
    cpus = 2
    memory = 1024
    disk_size = 10240
    guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
    guest_additions_url = ""
    guest_os_type = "docker_64"
    hard_drive_interface = "sata"
    headless = false
    http_content = {
         "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", {})
    }
    iso_checksum = local.iso_checksum
    iso_url = local.iso_url
    output_directory = "${var.output_directory}/packer-build/output/artifacts/${local.vm_name}/virtualbox/"
    shutdown_command = local.shutdown_command
    ssh_password = "vagrant"
    ssh_port = 22
    ssh_timeout = "10000s"
    ssh_username = "vagrant"
    virtualbox_version_file = ".vbox_version"
    vm_name = "${local.vm_name}"
    vboxmanage = [
        ["modifyvm", "{{.Name}}", "--vram", "128"],
        ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
        ["modifyvm", "{{.Name}}", "--vrde", "off"],
        ["modifyvm", "{{.Name}}", "--rtcuseutc", "on"]
    ]
}

build {
    name = "builder"

    sources = [
        "source.virtualbox-iso.cloudtools",
    ]

    provisioner "shell" {
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/setup-os-scripts/update.sh",
            "${path.root}/setup-os-scripts/sshd.sh",
            "${path.root}/setup-os-scripts/networking.sh",
            "${path.root}/setup-os-scripts/sudoers.sh",
            "${path.root}/setup-os-scripts/vagrant-conf.sh",
            "${path.root}/setup-os-scripts/systemd.sh",
            "${path.root}/setup-os-scripts/shell-conf.sh"
        ] 
    }

    provisioner "shell" {
        only = ["virtualbox-iso.cloudtools"]
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/setup-os-scripts/virtualbox.sh"
        ] 
    }

    provisioner "shell" {
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        scripts = [
            "${path.root}/provisions/tools.sh",
        ] 
    }

    provisioner "shell" {
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/setup-os-scripts/cleanup.sh",
            "${path.root}/setup-os-scripts/minimize.sh"
        ] 
    }

    post-processors {
        post-processor "vagrant" {
          keep_input_artifact = false
          output = "${var.output_directory}/packer-build/output/boxes/${local.vm_name}/{{.Provider}}/{{.BuildName}}.box"
          vagrantfile_template = "${path.root}/vagrantfile.rb"
        }
        post-processor "manifest" {
            output = "${var.output_directory}/packer-build/output/boxes/${local.vm_name}/manifest.json"
            strip_path = true
        }
    }

}