#!/bin/sh

DISK=$1
EFI_PART=1
ZFS_PART=2


# partition 1 - EFI
sgdisk -n$EFI_PART:2048:+512M -t#$EFI_PART:EF00 $DISK
# partition 2 - ZFS
sgdisk -n$ZFS_PART:0:0 -t$ZFS_PART:BF01 $DISK


zpool create -f \
    -o ashift=12 \
    -o autotrim=on \
    -O mountpoint=none \
    -O acltype=posixacl \
    -O canmount=off \
    -O compression=lz4 \
    -O devices=off \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O encryption=aes-256-gcm \
    -O keyformat=passphrase   \
    -O keylocation=prompt     \
    rpool $DISK$ZFS_PART

zfs create -o mountpoint=legacy rpool/roots
zfs create -o mountpoint=legacy rpool/roots/nixos
zfs create -o mountpoint=legacy rpool/roots/nixos/nix
zfs create -o mountpoint=legacy rpool/home

mkfs.vfat $DISK$EFI_PART

mount -t zfs rpool/roots/nixos /mnt

mkdir /mnt/nix
mount -t zfs rpool/roots/nixos/nix /mnt/nix

mkdir /mnt/home
mount -t zfs rpool/home /mnt/home

mkdir /mnt/boot
mount $DISK$EFI_PART /mnt/boot


nixos-generate-config --root /mnt


cat <<EOT > /mnt/etc/nixos/configuration.nix
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes="/dev/disk/by-part-uuid";

  networking.hostName = "nixos"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.hostId = "$(head -c4 /dev/urandom | od -A none -t x4 | sed 's/^ *//g')";

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tomas = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd"]; # Enable ‘sudo’ for the user.
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    mc
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  virtualisation.libvirtd.enable = true;
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  boot.extraModprobeConfig = "options kvm_intel nested=1\noptions kvm_amd nested=1";


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
EOT


nixos-install

umount /mnt/boot
umount /mnt/home
umount /mnt/nix
umount /mnt
zpool export rpool