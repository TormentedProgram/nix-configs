# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
    home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/master.tar.gz;
    nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export LIBVA_DRIVER_NAME,nvidia
      export __GL_VRR_ALLOWED,1
      export WLR_DRM_NO_ATOMIC,1
      exec "$@"
    '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  nix.settings = {
    download-buffer-size = 524288000; # 500 MiB
    experimental-features = [ "nix-command" "flakes" ];
  };

  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    efiSupport = true;
    device = "nodev";
  };

  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "chromasen-nix"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Australia/Sydney";
  
  programs.fish.enable = true;  
  users.defaultUserShell = pkgs.fish;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  
  nixpkgs.config.allowUnfree = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true; # recommended for most users
  };

  services.gvfs.enable = true;
  programs.thunar = {
    enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland"; # start Hyprland with a TUI login manager
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tormented = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      equibop
      vscodium
      steam
      protonup-qt
      lutris
      xfce.tumbler
      ffmpegthumbnailer
      github-desktop
      tree
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau
        libvdpau-va-gl 
        nvidia-vaapi-driver
        vdpauinfo
        libva
        libva-utils	
        intel-media-driver
      ];
  	};

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      open = false;
      modesetting.enable = true;
      nvidiaSettings = true;
      nvidiaPersistenced = false;
    };
  };

  home-manager.backupFileExtension = "bkp";  
  home-manager.users.tormented = { pkgs, ...}: {
    home.packages = with pkgs; [
    	xfce.thunar
        thunderbird
        xarchiver
        starship
        fish
        fastfetch
        rofi-wayland
        alacritty
        librewolf
        yt-dlp
        waybar
    ];
    home.stateVersion = "25.05";

    programs.fish = {
    	enable = true;
    	shellInit = ''
    	    source (starship init fish --print-full-init | psub)
    	'';
    	interactiveShellInit = ''
    	    set fish_greeting
    	    fastfetch
    	'';
    	shellAbbrs = {
    	    nix-update = "sudo nixos-rebuild switch";
    	};
    };

    programs.alacritty = {
    	enable = true;
    	settings = {
    	    terminal.shell = {
    	        program = "fish";
    	    };
    	};
    };
    
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      xwayland.enable = true;
      settings = {
        "$mod" = "SUPER";
        "$term" = "alacritty";
        "$browser" = "librewolf";
        "$discord" = "equibop";
        "$filemanager" = "thunar";

        exec-once = [
          "waybar"
          "swww-daemon"
          "swww img '/home/tormented/wallpaper.png'"
        ];

        monitor = [
          "Virtual-1, 2560x1440@240,0x0,1.6"
          "DP-1, 2560x1440@240,0x0,1.6"
          "HDMI-A-2, 1920x1080@144,1600x0,1.2"
        ];

        bind = [
          # mouse movements
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizeactive"
          "$mod ALT, mouse:272, resizeactive"

          # keybinds
          "$mod, Q, exec, $term"
          "$mod, F, exec, $browser"
          "$mod, D, exec, $discord"
          "$mod, E, exec, $filemanager"
          "$mod, C, killactive"
          "$mod, W, togglefloating"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (i:
              let ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
      };
    };

    home.sessionVariables.NIXOS_OZONE_WL = "1";
  };
  
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    nvidia-offload
    gedit
    wget
    git
    gvfs
    swww
    ffmpeg
    wl-clipboard
    grimblast
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}

