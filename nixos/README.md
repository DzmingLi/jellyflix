# Jellyflix NixOS Module

This directory contains a NixOS module for deploying Jellyflix as a web application on NixOS servers.

## Features

- 🚀 Declarative configuration for Jellyflix web deployment
- 🔒 Automatic HTTPS with Let's Encrypt via Caddy
- ⚡ Caddy web server with automatic TLS and HTTP/2
- 🎯 Optimized caching and compression
- 🔥 Firewall management
- 📦 Built-in Flutter web build

## Installation

### Method 1: Using Flakes (Recommended)

Add Jellyflix to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jellyflix = {
      url = "github:jellyflix-app/jellyflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, jellyflix, ... }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        jellyflix.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### Method 2: Without Flakes

Add this to your `configuration.nix`:

```nix
{ config, pkgs, ... }:

let
  jellyflix = builtins.fetchGit {
    url = "https://github.com/jellyflix-app/jellyflix";
    ref = "main";
  };
in {
  imports = [
    (jellyflix + "/nixos/module.nix")
  ];

  # ... rest of configuration
}
```

### Method 3: Local Development

If you have the repository cloned locally:

```nix
{ config, pkgs, ... }:

{
  imports = [
    /path/to/jellyflix/nixos/module.nix
  ];

  # ... rest of configuration
}
```

## Configuration Examples

### Basic Configuration

Minimal setup with automatic HTTPS (Caddy handles everything):

```nix
{
  services.jellyflix = {
    enable = true;
    domain = "jellyflix.example.com";
    openFirewall = true;

    # Optional but recommended for certificate expiry notifications
    acmeEmail = "admin@example.com";
  };
}
```

That's it! Caddy will automatically:
- Obtain SSL certificates from Let's Encrypt
- Handle HTTP to HTTPS redirects
- Renew certificates automatically
- Enable HTTP/2

Note: `acmeEmail` is optional but recommended - Let's Encrypt will use it to notify you about certificate expiry.

### Without SSL (Development)

For testing or local deployment:

```nix
{
  services.jellyflix = {
    enable = true;
    domain = "localhost";
    enableSSL = false;
    port = 8080;
    openFirewall = true;
  };
}
```

Access at: `http://localhost:8080`

### Advanced Configuration

With custom Caddy directives:

```nix
{
  services.jellyflix = {
    enable = true;
    domain = "jellyflix.example.com";
    acmeEmail = "admin@example.com";
    openFirewall = true;

    extraCaddyConfig = ''
      # Rate limiting
      rate_limit {
        zone dynamic {
          key {remote_host}
          events 100
          window 1m
        }
      }

      # Basic authentication (optional)
      basicauth {
        username $2a$14$Zkx19XLiW6VYouLHR5NmfOFU0z2GTNmpkT/5qqR7hx4IjWJPDhjvG
      }

      # Custom logging
      log {
        output file /var/log/caddy/jellyflix.log
        level INFO
      }
    '';
  };
}
```

### Behind Another Reverse Proxy

If you already have Caddy or another reverse proxy:

```nix
{
  services.jellyflix = {
    enable = true;
    domain = "localhost";
    enableSSL = false;
    port = 8080;
    openFirewall = false;
  };

  # Then configure your main reverse proxy
  services.caddy.virtualHosts."jellyflix.example.com".extraConfig = ''
    reverse_proxy localhost:8080
  '';
}
```

## Configuration Options

### `services.jellyflix.enable`
- **Type**: boolean
- **Default**: `false`
- **Description**: Whether to enable the Jellyflix web application

### `services.jellyflix.domain`
- **Type**: string
- **Required**: yes
- **Example**: `"jellyflix.example.com"`
- **Description**: Domain name for the Jellyflix web application

### `services.jellyflix.port`
- **Type**: port (1-65535)
- **Default**: `8080`
- **Description**: Port for the internal web server (not exposed directly)

### `services.jellyflix.enableSSL`
- **Type**: boolean
- **Default**: `true`
- **Description**: Whether to enable automatic HTTPS via Caddy (requires valid domain)

### `services.jellyflix.acmeEmail`
- **Type**: null or string
- **Default**: `null`
- **Optional**: Yes (but recommended for production)
- **Example**: `"admin@example.com"`
- **Description**: Email address for Let's Encrypt notifications about certificate expiry and issues. If not provided, Caddy will still obtain certificates but you won't receive notifications.

### `services.jellyflix.extraCaddyConfig`
- **Type**: multi-line string
- **Default**: `""`
- **Description**: Extra Caddy directives to add to the site block
- **Example**: See Advanced Configuration section

### `services.jellyflix.dataDir`
- **Type**: path
- **Default**: `"/var/lib/caddy"`
- **Description**: Directory for Caddy data (certificates, ACME account, etc.)

### `services.jellyflix.openFirewall`
- **Type**: boolean
- **Default**: `false`
- **Description**: Whether to automatically open firewall ports 80 and 443

## DNS Configuration

Before enabling SSL, ensure your DNS is configured:

1. Create an A record pointing to your server's IP:
   ```
   jellyflix.example.com  A  203.0.113.1
   ```

2. Wait for DNS propagation (can take a few minutes to 48 hours)

3. Verify with: `dig jellyflix.example.com`

## Firewall Notes

If `openFirewall = true`, the module will open:
- Port 80 (HTTP) - always
- Port 443 (HTTPS) - if `enableSSL = true`

Make sure your hosting provider also allows these ports.

## Troubleshooting

### Certificate Issues

Check Caddy logs:
```bash
systemctl status caddy
journalctl -u caddy -f
```

Check certificate status:
```bash
# List certificates
caddy list-certificates

# Test ACME challenge
curl http://jellyflix.example.com/.well-known/acme-challenge/test
```

### Caddy Issues

Validate Caddyfile:
```bash
caddy validate --config /etc/caddy/Caddyfile
```

Check Caddy service:
```bash
systemctl status caddy
journalctl -u caddy -n 50
```

Reload Caddy after config changes:
```bash
systemctl reload caddy
```

### Build Issues

Rebuild the system with more verbose output:
```bash
nixos-rebuild switch --show-trace
```

### Check if Jellyflix is accessible

```bash
# Without SSL
curl http://jellyflix.example.com

# With SSL
curl https://jellyflix.example.com
```

## Updating

### With Flakes

Update the input and rebuild:
```bash
nix flake update jellyflix
nixos-rebuild switch --flake .#myserver
```

### Without Flakes

The module will automatically fetch the latest version on rebuild. To force an update:
```bash
# Clear nix-prefetch cache if needed
nixos-rebuild switch
```

## Security Considerations

1. **Always use SSL in production** - Set `enableSSL = true` and `enableACME = true`
2. **Firewall** - Only open ports you need
3. **Keep updated** - Regularly update your system: `nixos-rebuild switch --upgrade`
4. **Access control** - Consider using nginx auth or a VPN for additional security
5. **Rate limiting** - Add rate limiting in nginx.extraConfig for public deployments

## Example: Complete Production Setup

```nix
{ config, pkgs, ... }:

{
  imports = [
    /path/to/jellyflix/nixos/module.nix
  ];

  services.jellyflix = {
    enable = true;
    domain = "jellyflix.example.com";
    acmeEmail = "admin@example.com";
    openFirewall = true;

    extraCaddyConfig = ''
      # Rate limiting
      rate_limit {
        zone dynamic {
          key {remote_host}
          events 100
          window 1m
        }
      }

      # Custom logging
      log {
        output file /var/log/caddy/jellyflix.log {
          roll_size 100mb
          roll_keep 5
        }
        level INFO
      }
    '';
  };

  # Optional: Enable fail2ban for additional protection
  services.fail2ban.enable = true;
}
```

## License

Jellyflix is licensed under the GPL-3.0 license. See the main repository for details.
