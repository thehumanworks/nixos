{ username, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";
  system.stateVersion = 6;
}