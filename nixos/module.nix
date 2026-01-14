{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.jellyflix;

  # Build the Flutter web application
  jellyflixWeb = pkgs.stdenv.mkDerivation {
    pname = "jellyflix-web";
    version = "0.1.0";

    src = ../.;

    nativeBuildInputs = with pkgs; [
      flutter
      jq
    ];

    buildPhase = ''
      export HOME=$TMPDIR
      flutter config --no-analytics
      flutter config --enable-web
      flutter pub get
      flutter build web --release
    '';

    installPhase = ''
      mkdir -p $out/share/jellyflix
      cp -r build/web/* $out/share/jellyflix/
    '';
  };

  # Generate Caddyfile
  caddyConfig = pkgs.writeText "Caddyfile" ''
    ${if cfg.enableSSL then ''
      ${cfg.domain} {
        ${optionalString (cfg.acmeEmail != null) "email ${cfg.acmeEmail}"}

        root * ${cfg.package}/share/jellyflix
    '' else ''
      :${toString cfg.port} {
        root * ${cfg.package}/share/jellyflix
    ''}

      # Enable gzip compression
      encode gzip

      # Security headers
      header {
        # Enable HSTS
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        # Prevent clickjacking
        X-Frame-Options "SAMEORIGIN"
        # Prevent MIME sniffing
        X-Content-Type-Options "nosniff"
        # XSS protection
        X-XSS-Protection "1; mode=block"
        # Referrer policy
        Referrer-Policy "strict-origin-when-cross-origin"
        # Remove server header
        -Server
      }

      # Cache static assets
      @static {
        path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
      }
      header @static {
        Cache-Control "public, max-age=31536000, immutable"
      }

      # Don't cache index.html
      @html {
        path *.html
      }
      header @html {
        Cache-Control "no-cache, no-store, must-revalidate"
      }

      # Try files, fallback to index.html for SPA routing
      try_files {path} /index.html
      file_server

      ${cfg.extraCaddyConfig}
    }
  '';

in {
  options.services.jellyflix = {
    enable = mkEnableOption "Jellyflix web application";

    package = mkOption {
      type = types.package;
      default = jellyflixWeb;
      description = "The Jellyflix package to use";
    };

    domain = mkOption {
      type = types.str;
      example = "jellyflix.example.com";
      description = "Domain name for the Jellyflix web application";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for HTTP when SSL is disabled";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable automatic HTTPS via Caddy";
    };

    acmeEmail = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "admin@example.com";
      description = "Email address for Let's Encrypt ACME account";
    };

    extraCaddyConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        # Rate limiting
        rate_limit {
          zone static {
            key {remote_host}
            events 100
            window 1m
          }
        }
      '';
      description = "Extra Caddy configuration to add to the site block";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/caddy";
      description = "Directory for Caddy data (certificates, etc)";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open firewall ports for HTTP/HTTPS";
    };
  };

  config = mkIf cfg.enable {
    # Configure Caddy
    services.caddy = {
      enable = true;
      dataDir = cfg.dataDir;
      configFile = caddyConfig;
    };

    # Ensure Caddy user can read the web files
    systemd.services.caddy.serviceConfig = {
      ReadOnlyPaths = [ "${cfg.package}/share/jellyflix" ];
    };

    # Open firewall if requested
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 80 ] ++ optional cfg.enableSSL 443;
    };
  };
}
