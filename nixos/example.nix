# Example NixOS configuration for deploying Jellyflix
# Copy this file to your NixOS configuration and adjust as needed

{ config, pkgs, ... }:

{
  imports = [
    # Import the Jellyflix module
    # Adjust the path based on your setup:
    # - For flakes: automatically imported via nixosModules.default
    # - For non-flakes: ./path/to/jellyflix/nixos/module.nix
  ];

  # Basic production configuration with Caddy
  services.jellyflix = {
    enable = true;
    domain = "jellyflix.example.com";  # Replace with your domain
    openFirewall = true;

    # Optional: Provide email for Let's Encrypt notifications
    acmeEmail = "admin@example.com";   # Replace with your email or remove

    # Optional: Add custom Caddy configuration
    extraCaddyConfig = ''
      # Rate limiting
      rate_limit {
        zone dynamic {
          key {remote_host}
          events 100
          window 1m
        }
      }
    '';
  };

  # Optional: Additional security with fail2ban
  services.fail2ban = {
    enable = true;
  };
}

# Alternative configurations:

# 1. Development setup (no SSL):
# services.jellyflix = {
#   enable = true;
#   domain = "localhost";
#   enableSSL = false;
#   port = 8080;
#   openFirewall = true;
# };

# 2. Behind existing reverse proxy:
# services.jellyflix = {
#   enable = true;
#   domain = "localhost";
#   enableSSL = false;
#   port = 8080;
#   openFirewall = false;
# };
# # Then configure your main Caddy to forward:
# services.caddy.virtualHosts."jellyflix.example.com".extraConfig = ''
#   reverse_proxy localhost:8080
# '';

# 3. With basic authentication:
# services.jellyflix = {
#   enable = true;
#   domain = "jellyflix.example.com";
#   acmeEmail = "admin@example.com";
#   openFirewall = true;
#   extraCaddyConfig = ''
#     basicauth {
#       # Generate with: caddy hash-password
#       user $2a$14$...your-bcrypt-hash...
#     }
#   '';
# };
