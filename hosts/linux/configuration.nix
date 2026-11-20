{ ... }:
{
  imports = [ ];

  networking.hostName = "beelink";
  networking.networkmanager.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}