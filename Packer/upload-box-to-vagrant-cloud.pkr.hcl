variable "input_directory" {
    type = string
}

variable "version" {
    type = string
}

variable "version_description"{
  type = string
}

locals {
    vm_name = "cloudtools"
    box_files = [
            "${var.input_directory}/packer-build/output/boxes/${local.vm_name}/virtualbox/${local.vm_name}.box"
    ]
}

source "null" "cloudtools" {
  communicator = "none"
}

build {
  sources = ["source.null.cloudtools"]

  post-processors {
    post-processor "artifice" {
      files = local.box_files
    }
    post-processor "vagrant-cloud" {
      box_tag      = "Yohnah/CloudTools"
      keep_input_artifact = false
      version      = var.version
      version_description = "Built at ${var.version_description}"
    }
  }
}
