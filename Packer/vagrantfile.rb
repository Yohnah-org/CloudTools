# -*- mode: ruby -*-
# vi: set ft=ruby :

class VagrantPlugins::ProviderVirtualBox::Action::Network
  def dhcp_server_matches_config?(dhcp_server, config)
    true
  end
end

module OS
  def OS.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
      (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
      !OS.windows?
  end

  def OS.linux?
      OS.unix? and not OS.mac?
  end
end


Host_OS = "win"
if OS.windows?
  HostDir = ENV["USERPROFILE"]
  Aux = HostDir.split('\\')
  Aux.shift()
  GuestDir = "/" + Aux.join('/')
  Host_OS = "win"
end

if OS.mac?
  HostDir = ENV["HOME"]
  GuestDir = HostDir
  Host_OS = "mac"
end

if OS.linux?
  HostDir = ENV["HOME"]
  GuestDir = HostDir
  Host_OS = "linux"
end

$msg = <<MSG
Welcome to Cloud tools Linux box for Vagrant by Yohnah
=================================================

Host Operative System detected: #{Host_OS}

Further information, see: https://github.com/Yohnah-org/CloudTools

MSG

Vagrant.configure(2) do |config|
  config.vm.post_up_message = $msg
  config.ssh.shell = '/usr/bin/zsh'

  config.vm.synced_folder HostDir, GuestDir

  config.vm.provider "virtualbox" do |vb, override|
    vb.memory = 512
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--uart1", "off"]
    vb.customize ['modifyvm', :id, '--vrde', 'off']
    override.vm.network "private_network", type: "dhcp"
  end

end
