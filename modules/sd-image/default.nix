{ pkgs, lib, config, ... }:
let
  nixpkgs = import ../nixpkgs/cross-compilation.nix;
in
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
    ../installation-device.nix
    ../odroidhc4
  ];

  # set cross compiling
  nixpkgs.crossSystem.config = "aarch64-unknown-linux-gnu";

  # Use pinned packages
  nixpkgs.pkgs = import "${nixpkgs}" {
    inherit (config.nixpkgs) config localSystem crossSystem;
  };

  sdImage = {
    compressImage = false;
    # Use 512 MB for boot partition to fit multiple kernel versions
    firmwareSize = 512;
    # Copy u-boot bootloader to SD card
    postBuildCommands = ''
      dd if="${pkgs.uboot-hardkernel}" of="$img" conv=fsync,notrunc bs=512 skip=1 seek=1
      dd if="${pkgs.uboot-hardkernel}" of="$img" conv=fsync,notrunc bs=1 count=444
    '';
    # Fill the FIRMWARE partition with the u-boot files, linux kernel and initrd (ramdisk)
    populateFirmwareCommands = ''
      ${config.boot.loader.hardkernel-uboot.populateCmd} -c ${config.system.build.toplevel} -d ./firmware
    '';
    # Fill the root partition with this nix configuration in /etc/nixos
    # and create a mount point for the FIRMWARE partition at /boot
    populateRootCommands = ''
      mkdir -p ./files/boot
      mkdir -p ./files/etc/nixos
      cp ${../../configuration.nix} ./files/etc/nixos/configuration.nix
      cp -r ${../.} ./files/etc/nixos/modules
    '';
  };
}
