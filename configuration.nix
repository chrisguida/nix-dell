# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.extraSystemdUnitPaths = [ "/etc/systemd-mutable/system" ];

  networking.hostName = "nix-dell"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Mexico_City";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.xserver.displayManager.gdm.autoSuspend = false;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.suspend" ||
            action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
        {
            return polkit.Result.NO;
        }
    });
  '';

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cguida = {
    isNormalUser = true;
    description = "Chris Guida";
    extraGroups = [ "networkmanager" "wheel" "bitcoin" "clightning" ];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAyg23mUQq55zHvcjo+F8bVXDQ33b4uIhiYU99V3lX1 cguida@cg-acer"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQjOgrgPaeaCAMMgNpjayLgj6EPC4m32MSCklYyYsuU cguida@cg-lenovo"
    ];
    packages = with pkgs; [
      firefox
    #  thunderbird
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    magic-wormhole
    curl
    htop
    git
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 8332 50001 50002 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  nix.extraOptions = "experimental-features = nix-command flakes";
  nix-bitcoin.generateSecrets = true;
  nix-bitcoin.operator.name = "bitcoiner";
  # turn on tor for CLN
  nix-bitcoin.onionServices.clightning = {
    enable = true;
    public = true;
  };
  # CLN: set custom lightningd start flags this way. 
  # wanted to set --database-upgrade=true for Release Candidate builds. 
  # useful, not fully recommended
#  systemd.services.clightning.serviceConfig.ExecStart = lib.mkForce "${config.services.clightning.package}/bin/lightningd --lightning-dir=${config.services.clightning.dataDir} --database-upgrade=true";
  systemd.services.clightning.serviceConfig.Environment = lib.mkForce "RUST_LOG=trace";
  services.clightning = {
    enable = true;
    # this lets me pick a tag/commit for a CLN build
    package =  pkgs.clightning.overrideAttrs (
      orig:
#      let version = "v23.02.2"; in
      let version = "44c5b523683160e8c20bda200c6a5a59ea40bc5e"; in
      {
        version = version;
        src = pkgs.fetchFromGitHub {
          owner = "niftynei";
          repo = "lightning";
          rev = "${version}";
          fetchSubmodules = true;
#          sha256 = "sha256-UgEJ0K8G2VvyVaY57pxOeiSWtn2z4CRcye5meH2Ffco=";
          sha256 = "sha256-tWxnuVHhXl7JWwMxQ46b+Jd7PeoMVr7pnWXv5Of5AeI=";
        };
        # i run CLN as developer + with experimental-features on
#        configureFlags = [ "--enable-developer" "--disable-valgrind" "--enable-experimental-features" ];
#        makeFlags = [ "VERSION=${version}" ];
#        log-file=/var/lib/clightning/logs/log
    });
    extraConfig = ''
        alias=shadowysupernode
        rgb=CF0599
        log-level=debug
        log-timestamps=true
        fee-base=1000
        fee-per-satoshi=5
        allow-deprecated-apis=false
        wumbo
        experimental-offers
        experimental-dual-fund
        experimental-websocket-port=9999
        funder-policy=match
        funder-policy-mod=100
        funder-per-channel-max=10000000sat
        funder-per-channel-min=100000sat
        funder-min-their-funding=100000sat
        lease-fee-base-sat=500sat
        lease-fee-basis=60
        channel-fee-max-base-msat=100sat
        channel-fee-max-proportional-thousandths=2
    '';
    plugins.summary.enable = true;
#    plugins.clboss.enable = true;
#    plugins.clboss.acknowledgeDeprecation = true;
  };
#  systemd.services.clightning.serviceConfig = let
#    cfg = config.services.clightning;
#  in
#    lib.mkForce {
#      ExecStart = "${cfg.package}/bin/lightningd --lightning-dir=${cfg.dataDir}";
#      # or use this, analogous to your configuration.nix
#      ExecStart = "${cfg.package}/bin/lightningd --lightning-dir=${cfg.dataDir} --database-upgrade=true";
#      User = cfg.user;
#      Restart = "on-failure";
#      RestartSec = "10s";
#    };

  systemd.services.bitcoind.serviceConfig.TimeoutStartSec = lib.mkForce "48h";
  services.bitcoind = {
    enable = true;
    disablewallet = true;
    dbCache = 8192;
    txindex = true;
    rpc = {
      address = "0.0.0.0";
      allowip = [ "192.168.100.0/24" "100.75.154.0/24" ];
    };
    extraConfig = ''
      blockfilterindex=1
      peerblockfilters=1
#      signet=1
#      [signet]
#      signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae
#      addnode=45.79.52.207:38333
#      dnsseed=0
#      signetblocktime=30
    '';
  };
  services.fulcrum = {
    enable = true;
    address = "0.0.0.0";
    #extraConfig = "ssl = 0.0.0.0:50002"; 
  };
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  services.tailscale.enable = true;
}
