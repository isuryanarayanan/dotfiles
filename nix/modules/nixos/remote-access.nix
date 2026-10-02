{ ... }:

{
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      # Disable only after key-based or Tailscale SSH access is verified.
      PasswordAuthentication = true;
    };
  };
}
