{ config, pkgs, lib, ... }:
{
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # !!! Set to specific linux kernel version
  boot.kernelPackages = pkgs.linuxPackages;

  # Disable ZFS on kernel 6
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "xfs"
    "cifs"
    "ntfs"
  ];

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  boot.kernelParams = [ "cma=256M" ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    # Prior to 19.09, the boot partition was hosted on the smaller first partition
    # Starting with 19.09, the /boot folder is on the main bigger partition.
    # The following is to be used only with older images.
    /*
      "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
      };
    */
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "btrfs";
    };
  };

  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  # systemPackages
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    nano
    bind
    iptables
    python3
    docker-compose
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Some sample service.
  # Use dnsmasq as internal LAN DNS resolver.
#  services.dnsmasq = {
#    enable = false;
#    settings.servers = [ "8.8.8.8" "8.8.4.4" "1.1.1.1" ];
#    settings.extraConfig = ''
#      address=/fenrir.test/192.168.100.6
#      address=/recalune.test/192.168.100.7
#      address=/eth.nixpi.test/192.168.100.3
#      address=/wlan.nixpi.test/192.168.100.4
#    '';
#  };

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
    };
  };


  virtualisation.docker.enable = true;

  networking.firewall.enable = false;


  # WiFi
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };

  # Networking
  networking = {
    # useDHCP = true;
    interfaces.wlan0 = {
      useDHCP = true;
    };
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.1.2";
        prefixLength = 24;
      }];
    };

    # Enabling WIFI
    wireless.enable = true;
    wireless.interfaces = [ "wlan0" ];
    # If you want to connect also via WIFI to your router
    # wireless.networks."SATRIA".psk = "wifipassword";
    # You can set default nameservers
    # nameservers = [ "192.168.100.3" "192.168.100.4" "192.168.100.1" ];
    # You can set default gateway
    # defaultGateway = {
    #  address = "192.168.1.1";
    #  interface = "eth0";
    # };
  };

  # forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv4.tcp_ecn" = true;
  };

  # put your own configuration here, for example ssh keys:
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = true;
  users.groups = {
    nixos = {
      gid = 1000;
      name = "marc";
    };
  };
  users.users = {
    marc = {
      uid = 1000;
      home = "/home/marc";
      name = "marc";
      group = "marc";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" ];
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    # This is my public key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClPIanBAeoqiz3vFLtQdS5lMHeaqtUD8aHPZ0z8JtkYVTiWxv4qHaD9RkPnxgnihAB2oZ+mKEQcHeKi55Qt5fWXr4ytBwSIIBfaX3r4IfuQkAkFHWW0izKz9K6k7xHVFLdjxaCI1PKo7ApH4cpCRHMrANHDdfr5zL1vwRVv3S/uWm5dXVvUKh/Uu2fMi/wYCGXAzOmpQIRlT2Uid1+r8u0Q08H09j/pQn+7OTAHgjaQmf7eZNN7wHfPz4kAOqQHZGnLJ2tKWTBMn9YvgzxJcjqkRwgBNVthMEzfX5M1ymPHZjPxpsD4CiY89mdnBcQ0vVI7CqURysiFL0100n3VS9x marc@localhost"
  ];
  system.stateVersion = "23.05";
}
