# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
    home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/master.tar.gz;
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

  boot.kernelParams = [
    "systemd.mask=systemd-vconsole-setup.service"
    "systemd.mask=dev-tpmrm0.device" #this is to mask that stupid 1.5 mins systemd bug
    "nowatchdog" 
    "modprobe.blacklist=sp5100_tco" #watchdog for AMD
    "modprobe.blacklist=iTCO_wdt" #watchdog for Intel
  ];

  boot.initrd = { 
    availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
    kernelModules = [ ];
  };

  boot.loader.systemd-boot = {
    enable = true;
  };

  boot.loader.efi.canTouchEfiVariables = true;

  # Use Zen kernel.
  boot.kernelPackages = pkgs.linuxPackages_zen;

  networking = {
    networkmanager.enable = true;
    hostName = "chromasen-nix"; # Define your hostname.
    timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
  }; 

  # Set your time zone.
  i18n.defaultLocale = "en_AU.UTF-8";
  services.automatic-timezoned.enable = true; #based on IP location

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };
  
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
  
  fonts = {
    packages = with pkgs; [
      noto-fonts
      fira-code
      noto-fonts-cjk-sans
      jetbrains-mono
      nerd-fonts.jetbrains-mono # unstable
      nerd-fonts.fira-code # unstable
      nerd-fonts.fantasque-sans-mono #unstable
      ];
  };

  nixpkgs.config.allowUnfree = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  	xwayland.enable = true;
    withUWSM = true; # recommended for most users
  };

  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
    ];
  };

  programs.waybar.enable = true;
  programs.xwayland.enable = true;

  services.gvfs.enable = true;
  programs.thunar = {
    enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland"; # start Hyprland with a TUI login manager
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tormented = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ 
      "wheel" 
      "networkmanager"
      "libvirtd"
      "scanner"
      "lp"
      "video" 
      "input" 
      "audio"  
    ];
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
  
  services.xserver.videoDrivers = [ "nvidia" ];

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
      ];
  	};

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      open = false;
      modesetting.enable = true;
      nvidiaSettings = true;
      #nvidiaPersistenced = false;
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
        mpv
        qimgv
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
        env = [
          # Hint Electron apps to use Wayland
          "NIXOS_OZONE_WL,1"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "QT_QPA_PLATFORM,wayland"
        ];

        "$mod" = "SUPER";
        "$term" = "alacritty";
        "$browser" = "librewolf";
        "$discord" = "equibop";
        "$filemanager" = "thunar";

        exec-once = [
          "waybar"
          "swww-daemon"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
        ];

        general = {
          gaps_in = 4;
          gaps_out = 10;

          resize_on_border = true;

          border_size = 2;
          layout = "dwindle";
        };

        decoration = {
          rounding = 9;

          active_opacity = 0.85;
          inactive_opacity = 0.85;

          shadow = {
            enabled = false;
          };
        };

        blur = {
          enabled = true;
          size = 4;
          passes = 4;
          new_optimizations = true;
          ignore_opacity = true;
          xray = false;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        windowrulev2 = [
          "opacity 0.80 0.80,class:^(VS[Cc]odium)$"
          "opacity 0.80 0.80,class:^(GitHub Desktop)$"
          "opacity 0.80 0.80,class:^(equibop)$"
          "opacity 0.80 0.80,class:^(feishin)$"
          "opacity 0.80 0.80,class:^(thunderbird)$"
          "opacity 0.80 0.80,class:^(Godot)$"

          "center,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"
          "nofocus,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"
          "noborder,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"

          "stayfocused,class:^(jetbrains-.*)$,title:^( )$,floating:1"
          "noborder,class:^(jetbrains-.*)$,title:^( )$,floating:1"

          "nofocus,class:^(jetbrains-.*)$,title:^(win.*)$,floating:1"

          "opacity 0.80 0.80,class:^([Tt]hunar)$"
          "opacity 0.80 0.80,class:^(org.prismlauncher.PrismLauncher)$"
          "opacity 0.80 0.80,class:^(feishin)$"
          "opacity 0.80 0.80,class:^(xarchiver)$"
          "opacity 0.80 0.80,class:^(qt5ct)$"
          "opacity 0.80 0.80,class:^(qt6ct)$"
          "opacity 0.80 0.80,class:^(kvantummanager)$"
          "opacity 0.80 0.70,class:^(org.pulseaudio.pavucontrol)$"
          "opacity 0.80 0.70,class:^(blueman-manager)$"
          "opacity 0.80 0.70,class:^(nm-applet)$"
          "opacity 0.80 0.70,class:^(nm-connection-editor)$"
          "opacity 0.80 0.70,class:^(org.kde.polkit-kde-authentication-agent-1)$"
          "opacity 0.80 0.70,class:^(polkit-gnome-authentication-agent-1)$"
          "opacity 0.80 0.70,class:^(org.freedesktop.impl.portal.desktop.gtk)$"
          "opacity 0.80 0.70,class:^(org.freedesktop.impl.portal.desktop.hyprland)$"
          "opacity 0.70 0.70,class:^(steamwebhelper)$"

          "opacity 0.80 0.80,class:^(com.github.tchx84.Flatseal)$"
          "opacity 0.80 0.80,class:^(com.obsproject.Studio)$ # Obs-Qt"
          "opacity 0.80 0.80,class:^(net.davidotek.pupgui2)$ # ProtonUp-Qt"
          "opacity 0.80 0.80,class:^(yad)$ # Protontricks-Gtk"

          "float,class:^(org.kde.dolphin)$,title:^(Progress Dialog — Dolphin)$"
          "float,class:^(org.kde.dolphin)$,title:^(Copying — Dolphin)$"
          "float,class:^([Tt]hunar)$,title:^(File Operation Progress)$"
          "size 50% 50%,class:^(librewolf)$,title:^(Save Image)$"
          "float,class:^(xarchiver)$"
          "float,title:.*[Ww]inetricks.*"
          "float,title:^(About Mozilla Firefox)$"
          "float,class:^(alacritty)$"
          "float,class:^(qimgv)$"

          "size 50% 50%,class:^(qimgv)$"

          "float,class:^(mpv)$"
          "float,class:^(qt5ct)$"
          "float,class:^(qt6ct)$"
          "float,class:^(org.pulseaudio.pavucontrol)$"
          "float,class:^(blueman-manager)$"
          "float,class:^(nm-applet)$"
          "float,class:^(nm-connection-editor)$"
          "float,class:^(org.kde.polkit-kde-authentication-agent-1)$"

          "float,class:^(net.davidotek.pupgui2)$ # ProtonUp-Qt"
          "float,class:^(yad)$ # Protontricks-Gtk"

          "float,title:^(Open)$"
          "float,title:^(Choose Files)$"
          "float,title:^(Save As)$"
          "float,title:^(Confirm to replace files)$"
          "float,title:^(File Operation Progress)$"
          "float,class:^(xdg-desktop-portal-gtk)$"
        ];

        debug = {
          disable_logs = false;
        };

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
    home.sessionVariables.QML_IMPORT_PATH = "${pkgs.hyprland-qt-support}/lib/qt-6/qml";
  };
  
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    gedit
    wget
    curl
    hypridle
    cliphist
    hyprland-qt-support # for hyprland-qt-support
    clang
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
  system.stateVersion = "25.11"; # Did you read the comment?
}

