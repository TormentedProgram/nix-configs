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
    "nvidia-drm.modeset=1" # Enables kernel modesetting for the proprietary NVIDIA driver.
    "nouveau.modeset=0" # Disables modesetting for the open-source Nouveau driver, preventing conflicts with proprietary NVIDIA drivers.
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
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
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

  programs.waybar.enable = true;

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

  programs.xwayland.enable = true;

  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true; # Thumbnail support for images
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.displayManager.gdm.enable = true;
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
      umu-launcher
      jetbrains-toolbox
      nicotine-plus
      nero-umu
      prismlauncher
      teams-for-linux
      gittyup
      xfce.tumbler
      xfce.xfce4-settings
      ffmpegthumbnailer
      obs-studio
      tree
      feishin
      navidrome
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

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  home-manager.backupFileExtension = "bkp";  
  home-manager.users.tormented = { pkgs, config, ...}: {
    home.packages = with pkgs; [
    	xfce.thunar
      thunderbird
      xarchiver
      starship
      fish
      fastfetch
      rofi-wayland
      hyprlock
      dconf
      alacritty
      adwaita-icon-theme
      orchis-theme
      librewolf
      yt-dlp
      waybar
      mpv
      vscodium
      qimgv
    ];
    home.stateVersion = "25.05";

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
    };

    gtk = {
      enable = true;
      theme = {
        name = "Orchis-Dark";
        package = pkgs.orchis-theme;
      };
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      cursorTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
    };

    home.sessionVariables.GTK_THEME = "Orchis-Dark";

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

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      theme = let
        inherit (config.lib.formats.rasi) mkLiteral;
      in {
        "*" = {
          #font = "Iosevka Nerd Font Medium 11";

          bg0 = mkLiteral "#1a1b26";
          bg1 = mkLiteral "#1f2335";
          bg2 = mkLiteral "#24283b";
          bg3 = mkLiteral "#414868";
          fg0 = mkLiteral "#c0caf5";
          fg1 = mkLiteral "#a9b1d6";
          fg2 = mkLiteral "#737aa2";
          red = mkLiteral "#f7768e";
          green = mkLiteral "#9ece6a";
          yellow = mkLiteral "#e0af68";
          blue = mkLiteral "#7aa2f7";
          magenta = mkLiteral "#9a7ecc";
          cyan = mkLiteral "#4abaaf";

          accent = mkLiteral "@red";
          urgent = mkLiteral "@yellow";

          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";

          margin = 0;
          padding = 0;
          spacing = 0;
        };

        "element-icon, element-text, scrollbar" = {
          cursor = mkLiteral "pointer";
        };

        "window" = {
          location = mkLiteral "center";
          width = mkLiteral "280px";
          x-offset = mkLiteral "4px";
          y-offset = mkLiteral "26px";

          background-color = mkLiteral "@bg1";
          border = mkLiteral "1px";
          border-color = mkLiteral "@bg3";
          border-radius = mkLiteral "6px";
        };

        "inputbar" = {
          spacing = mkLiteral "8px";
          padding = mkLiteral "4px 8px";
          children = map mkLiteral [ "icon-search" "entry" ];

          background-color = mkLiteral "@bg0";
        };

        "icon-search, entry, element-icon, element-text" = {
          vertical-align = mkLiteral "0.5";
        };

        "textbox" = {
          padding = mkLiteral "4px 8px";
          background-color = mkLiteral "@bg2";
        };

        "listview" = {
          padding = mkLiteral "4px 0px";
          lines = 12;
          columns = 1;
          scrollbar = mkLiteral "true";
          fixed-height = mkLiteral "false";
          dynamic = mkLiteral "true";
        };

        "element" = {
          padding = mkLiteral "4px 8px";
          spacing = mkLiteral "8px";
        };

        "element normal urgent" = {
          text-color = mkLiteral "@urgent";
        };

        "element normal active" = {
          text-color = mkLiteral "@accent";
        };
        
        "element alternate active" = {
          text-color = mkLiteral "@accent";
        };

        "element selected" = {
          text-color = mkLiteral "@bg1";
          background-color = mkLiteral "@accent";
        };

        "element selected urgent" = {
          background-color = mkLiteral "@urgent";
        };

        "element-icon" = {
          size = mkLiteral "0.8em";
        };

        "element-text" = {
          text-color = mkLiteral "inherit";
        };

        "scrollbar" = {
          handle-width = mkLiteral "4px";
          handle-color = mkLiteral "@fg2";
          padding = mkLiteral "0 4px";
        };
      };
    };

    programs.waybar = {
      enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          modules-center = [ "hyprland/workspaces" ];
          modules-left = [
            "custom/startmenu"
            "custom/arrow6"
            "pulseaudio"
            "cpu"
            "memory"
            "idle_inhibitor"
            "custom/arrow7"
            "hyprland/window"
          ];
          modules-right = [
            "custom/arrow4"
            "custom/hyprbindings"
            "custom/arrow3"
            "custom/notification"
            "custom/arrow3"
            "custom/exit"
            "battery"
            "custom/arrow2"
            "tray"
            "custom/arrow1"
            "clock"
          ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              default = " ";
              active = " ";
              urgent = " ";
            };
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };
          "clock" = {
            format = '' {:L%I:%M %p}'';
            tooltip = true;
            tooltip-format = "<big>{:%A, %d.%B %Y }</big>\n<tt><small>{calendar}</small></tt>";
          };
          "hyprland/window" = {
            max-length = 22;
            separate-outputs = false;
          };
          "memory" = {
            interval = 5;
            format = " {}%";
            tooltip = true;
          };
          "cpu" = {
            interval = 5;
            format = " {usage:2}%";
            tooltip = true;
          };
          "disk" = {
            format = " {free}";
            tooltip = true;
          };
          "network" = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-ethernet = " {bandwidthDownOctets}";
            format-wifi = "{icon} {signalStrength}%";
            format-disconnected = "󰤮";
            tooltip = false;
          };
          "tray" = {
            spacing = 12;
          };
          "pulseaudio" = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "sleep 0.1 && pavucontrol";
          };
          "custom/exit" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && hyprlock";
          };
          "custom/startmenu" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && rofi -show drun";
          };
          "custom/hyprbindings" = {
            tooltip = false;
            format = "󱕴";
            on-click = "sleep 0.1 && list-keybinds";
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            tooltip = "true";
          };
          "custom/notification" = {
            tooltip = false;
            format = "{icon} {}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "sleep 0.1 && task-waybar";
            escape = true;
          };
          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󱘖 {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            on-click = "";
            tooltip = false;
          };
          "custom/arrow1" = {
            format = "";
          };
          "custom/arrow2" = {
            format = "";
          };
          "custom/arrow3" = {
            format = "";
          };
          "custom/arrow4" = {
            format = "";
          };
          "custom/arrow5" = {
            format = "";
          };
          "custom/arrow6" = {
            format = "";
          };
          "custom/arrow7" = {
            format = "";
          };
        }
      ];

      style = lib.concatStrings [
        ''
          * {
            font-family: JetBrainsMono Nerd Font Mono;
            font-size: 14px;
            border-radius: 0px;
            border: none;
            min-height: 0px;
          }
          window#waybar {
            background: rgba(28, 28, 28, 0.7);
            color: #e9e9f4;
          }
          #workspaces button {
            padding: 0px 5px;
            background: transparent;
            color: #62d6e8;
          }
          #workspaces button.active {
            color: #e9e9f4;
            background: rgba(28, 28, 28, 0.7);
          }
          #workspaces button:hover {
            color: #e9e9f4;
          }
          tooltip {
            background: rgba(28, 28, 28, 0.7);
            border: 1px solid #e9e9f4;
            border-radius: 12px;
          }
          tooltip label {
            color: #e9e9f4;
          }
          #window {
            padding: 0px 10px;
          }
          #pulseaudio, #cpu, #memory, #idle_inhibitor {
            padding: 0px 10px;
            background: #62d6e8;
            color: rgba(28, 28, 28, 0.7);
          }
          #custom-startmenu {
            color: #4d4f68;
            padding: 0px 14px;
            font-size: 20px;
            background: #c3fffe;
          }
          #custom-hyprbindings, #network, #battery,
          #custom-notification, #custom-exit {
            background: #62d6e8;
            color: rgba(28, 28, 28, 0.7);
            padding: 0px 10px;
          }
          #tray {
            background: #4d4f68;
            color: rgba(28, 28, 28, 0.7);
            padding: 0px 10px;
          }
          #clock {
            font-weight: bold;
            padding: 0px 10px;
            color: rgba(28, 28, 28, 0.7);
            background: #c3fffe;
          }
          #custom-arrow1 {
            font-size: 24px;
            color: #c3fffe;
            background: #4d4f68;
          }
          #custom-arrow2 {
            font-size: 24px;
            color: #4d4f68;
            background: #62d6e8;
          }
          #custom-arrow3 {
            font-size: 24px;
            color: rgba(28, 28, 28, 0.7);
            background: #62d6e8;
          }
          #custom-arrow4 {
            font-size: 24px;
            color: #62d6e8;
            background: transparent;
          }
          #custom-arrow6 {
            font-size: 24px;
            color: #c3fffe;
            background: #62d6e8;
          }
          #custom-arrow7 {
            font-size: 24px;
            color: #62d6e8;
            background: transparent;
          }
        ''
      ];
    };

    programs.alacritty = {
    	enable = true;
    	settings = {
    	    terminal.shell = {
    	        program = "fish";
    	    };
          window = {
            opacity = 0.75;
          };
    	};
    };
    
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      xwayland = {
        enable = true;
      };
      settings = {
        env = [
          "LIBVA_DRIVER_NAME,nvidia"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          "__GL_VRR_ALLOWED,1"
          "WLR_DRM_NO_ATOMIC,1"
          "NIXOS_OZONE_WL,1"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "QT_QPA_PLATFORM,wayland"
          "GTK_THEME,Orchis-Dark"
          "QT_STYLE_OVERRIDE,adwaita-dark"
        ];

        "$mod" = "SUPER";
        "$term" = "alacritty";
        "$browser" = "librewolf";
        "$discord" = "equibop";
        "$filemanager" = "thunar";

        exec-once = [
          "pkill swww;sleep .5 && swww-daemon && swww img '$HOME/Pictures/wallpapers/current.png'"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          "systemctl --user start hyprpolkitagent"
          "navidrome"
          "thunderbird"
        ];

        general = {
          gaps_in = 4;
          gaps_out = 10;

          resize_on_border = true;

          border_size = 2;
          layout = "dwindle";
        };

        xwayland = {
          force_zero_scaling = true;
        };
        
        animations = {
          enabled = true;
          bezier = [
            "wind, 0.05, 0.9, 0.1, 1.05"
            "winIn, 0.1, 1.1, 0.1, 1.1"
            "winOut, 0.3, -0.3, 0, 1"
            "liner, 1, 1, 1, 1"
          ];
          animation = [
            "windows, 1, 6, wind, slide"
            "windowsIn, 1, 6, winIn, slide"
            "windowsOut, 1, 5, winOut, slide"
            "windowsMove, 1, 5, wind, slide"
            "border, 1, 1, liner"
            "borderangle, 1, 30, liner, loop"
            "fade, 1, 10, default"
            "workspaces, 1, 5, wind"
          ];
        };

        decoration = {
          rounding = 9;

          blur = {
            enabled = true;
            size = 6;
            passes = 3;
            ignore_opacity = true;
            new_optimizations = true;
            xray = false;
          };
          shadow = {
            enabled = false;
          };
        };
	
	      monitor = [
          "DP-1, 2560x1440@240,0x0,1.6"
          "HDMI-A-2, 1920x1080@144,1600x0,1.2"
        ];	

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        ecosystem = {
          no_donation_nag = true;
          no_update_news = true;
        };

        cursor = {
          sync_gsettings_theme = true;
          warp_on_change_workspace = 1;
          no_warps = true;
        };

        windowrulev2 = [
          "center,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"
          "nofocus,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"
          "noborder,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"

          "stayfocused,class:^(jetbrains-.*)$,title:^( )$,floating:1"
          "noborder,class:^(jetbrains-.*)$,title:^( )$,floating:1"

          "nofocus,class:^(jetbrains-.*)$,title:^(win.*)$,floating:1"
          
          "opacity 0.85 0.85,class:^([Tt]hunar)$"
          "opacity 0.90 0.90,class:^([Tt]hunderbird)$"
          "opacity 0.95 0.95,class:^(org.prismlauncher.PrismLauncher)$"
          "opacity 0.95 0.95,class:^(codium)$"
          "opacity 0.90 0.90,class:^(equibop)$"
          "opacity 0.95 0.95,class:^(com.github.gittyup.)$"
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
          "float,class:^([Aa]lacritty)$"
          "size 72% 70%,class:^([Aa]lacritty)$"
          "opacity 1.0, 1.0,class:^([Aa]lacritty)$"
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

        bindm = [
          # mouse movements
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bind = [
          # keybinds
          "$mod, Q, exec, $term"
          "$mod, F, exec, $browser"
          "$mod, D, exec, $discord"
          "$mod, E, exec, $filemanager"
	        "$mod, S, exec, rofi -show drun"
          "$mod, C, killactive"
          " , f11, fullscreen"
          "$mod Shift, S, exec, /usr/bin/screenshot.sh sf"
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
      extraConfig = "
        layerrule = blur,rofi
        layerrule = ignorezero,rofi
        layerrule = blur,notifications
        layerrule = ignorezero,notifications
        layerrule = blur,swaync-notification-window
        layerrule = ignorezero,swaync-notification-window
        layerrule = blur,swaync-control-center
        layerrule = ignorezero,swaync-control-center
        layerrule = blur,logout_dialog
        layerrule = blur,waybar
      ";
    };

    home.sessionVariables.NIXOS_OZONE_WL = "1";
    home.sessionVariables.QML_IMPORT_PATH = "${pkgs.hyprland-qt-support}/lib/qt-6/qml";
  };
  
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    headsetcontrol
    gedit
    wget
    curl
    hypridle
    gnome-themes-extra
    gsettings-desktop-schemas
    glib
    cliphist
    hyprland-qt-support # for hyprland-qt-support
    clang
    git
    imagemagick
    gvfs
    swww
    micromamba
    pipx
    ffmpeg
    wl-clipboard
    hyprpolkitagent
    pavucontrol
    grimblast
    swappy
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
