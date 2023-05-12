# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, boot, trivial, ... }:
let
  coreDiskIds = [
    "nvme-WD_BLACK_SN770_1TB_23085A802755"
    "nvme-WD_BLACK_SN770_1TB_23100L801126"
  ];
  backupDiskIds = [
    "wwn-0x5001b448b444e0e4"
    "wwn-0x5001b448b444e295"
  ];

  toPartitionId = diskId: partition: "${diskId}-part${toString partition}";
  toDevice = id: "/dev/disk/by-id/${id}";

  inherit (builtins) head toString map tail foldl';
  inherit (lib.trivial) flip;
in
{
  programs.i3status-rust = {
    networkInterface = "eno1";
    batteries = [
      {
        device = "battery_hidpp_battery_0";
        name = "";
      }
      {
        device = "battery_hidpp_battery_1";
        name = "";
      }
      {
        device = "ups_hiddev1";
        name = "";
      }
    ];
  };

  boot = {
    extraModulePackages = [ config.boot.kernelPackages.rtl88x2bu ];
    initrd = {
      availableKernelModules = [ "xhci_pci" "ehci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
    };
    kernelModules = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    loader = {
      efi.efiSysMountPoint = "/boot/efis/${toPartitionId (head coreDiskIds) 1}";
      grub = {
        enable = true;
        version = 2;
        devices = map toDevice coreDiskIds;
        efiSupport = true;
        extraInstallCommands = (toString (map
          (diskId: ''
            set -x
            ${pkgs.coreutils-full}/bin/cp -r \
              ${config.boot.loader.efi.efiSysMountPoint}/EFI \
              /boot/efis/${toPartitionId diskId 1}
            set +x
          '')
          (tail coreDiskIds)));
        zfsSupport = true;
      };
    };
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false; # zfs_force=1 in kernel command line.
  };

  swapDevices =
    let
      toSwapDevice = diskId:
        let
          partitionId = toPartitionId diskId 4;
          device = toDevice partitionId;
        in
        {
          device = "/dev/mapper/decrypted-${partitionId}";
          encrypted = {
            blkDev = device;
            enable = true;
            # Created with `dd count=1 bs=512 if=/dev/urandom of=/etc/nixos/secrets/swap.key`.
            keyFile = "/mnt-root/etc/nixos/secrets/swap.key";
            label = "decrypted-${partitionId}";
          };
        };
    in
    map toSwapDevice coreDiskIds;

  fileSystems =
    let
      fss =
        {
          "/boot" = {
            device = "boot/nixos/root";
            fsType = "zfs";
          };
          "/" = {
            device = "fast/nixos/root";
            fsType = "zfs";
          };
          "/etc/nixos" = {
            device = "fast/nixos/etc-nixos";
            fsType = "zfs";
            neededForBoot = true;
          };
          "/var" = {
            device = "fast/nixos/var";
            fsType = "zfs";
          };
          "/var/cache" = {
            device = "fast/nixos/var/cache";
            fsType = "zfs";
          };
          "/var/cache/builds" = {
            device = "fast/nixos/var/cache/builds";
            fsType = "zfs";
          };
          "/var/lib" = {
            device = "fast/nixos/var/lib";
            fsType = "zfs";
          };
          "/var/log" = {
            device = "fast/nixos/var/log";
            fsType = "zfs";
          };
          "/var/tmp" = {
            device = "fast/nixos/var/tmp";
            fsType = "zfs";
          };
          "/home" = {
            device = "fast/nixos/home";
            fsType = "zfs";
          };
          "/home/bakhtiyar/dev" = {
            device = "fast/nixos/home/dev";
            fsType = "zfs";
          };
          "/home/bakhtiyar/dump" = {
            device = "slow/root/dump";
            fsType = "zfs";
          };
          "/home/bakhtiyar/media" = {
            device = "slow/root/media";
            fsType = "zfs";
          };
          "/home/bakhtiyar/personal" = {
            device = "slow/root/personal";
            fsType = "zfs";
          };
          "/home/bakhtiyar/warehouse" = {
            device = "slow/root/warehouse";
            fsType = "zfs";
          };
        };
      insertBootFilesystem = fss: diskId:
        let
          partitionId = toPartitionId diskId 1;
        in
        fss // {
          "/boot/efis/${partitionId}" = {
            device = toDevice partitionId;
            fsType = "vfat";
            options = [
              "x-systemd.idle-timeout=1min"
              "x-systemd.automount"
              "noauto"
              "nofail"
              "noatime"
              "X-mount.mkdir"
            ];
          };
        };
    in
    foldl' insertBootFilesystem fss coreDiskIds;

  networking.hostId = "a7a93500";
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "22.11";
  services = {
    zfs = {
      autoScrub = {
        enable = true;
        interval = "*-*-* 04:00:00";
      };
      trim = {
        enable = true;
        interval = "*-*-* 05:00:00";
      };
      zed.settings = {
        ZED_DEBUG_LOG = "/tmp/zed.debug.log";
        ZED_EMAIL_ADDR = let at = "@"; in "bakhtiyarneyman+zed${at}gmail.com";
        ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
        ZED_EMAIL_OPTS = "@ADDRESS@";
        ZED_LOCKDIR = "/var/lock";

        ZED_NOTIFY_INTERVAL_SECS = 3600;
        ZED_NOTIFY_VERBOSE = false;

        ZED_USE_ENCLOSURE_LEDS = true;
        ZED_SCRUB_AFTER_RESILVER = true;
      };
    };
    zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [{
            type = "syslog";
            format = "human";
            level = "info";
          }];
        };
        jobs = [
          {
            name = "backups";
            type = "sink";
            serve = {
              type = "local";
              listener_name = "backups";
            };
            root_fs = "backups";
            recv = {
              placeholder = {
                encryption = "off";
              };
            };
          }
          {
            name = "backup_home";
            type = "push";
            connect = {
              type = "local";
              listener_name = "backups";
              client_identity = "iron";
            };
            filesystems = {
              "main/nixos/home<" = true;
              "main/nixos/home/.builds" = false;
            };
            snapshotting = {
              type = "periodic";
              interval = "10m";
              prefix = "zrepl_";
              timestamp_format = "iso-8601";
            };
            pruning = {
              keep_sender = [
                { type = "not_replicated"; }
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 23x1h | 6x1d | 3x1w | 12x4w | 4x365d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 23x1h | 6x1d | 3x1w | 12x4w | 4x365d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
      };
    };

    journal-brief.settings.exclusions = [
      {
        CODE_FILE = [ "src/login/logind-core.c" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        CODE_FILE = [ "src/core/job.c" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        MESSAGE_ID = [ "fc2e22bc-6ee6-47b6-b907-29ab34a250b1" ];
        SYSLOG_IDENTIFIER = [ "systemd-coredump" ];
      }
      {
        MESSAGE = [ "Failed to connect to coredump service: Connection refused" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        MESSAGE = [ "src/profile.c:ext_io_disconnected() Unable to get io data for Hands-Free Voice gateway: getpeername: Transport endpoint is not connected (107)" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        MESSAGE = [ "Gdm: Failed to contact accountsservice: Error calling StartServiceByName for org.freedesktop.Accounts: Refusing activation, D-Bus is shutting down." ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        MESSAGE = [ "DMAR: [Firmware Bug]: No firmware reserved region can cover this RMRR [0x000000003e2e0000-0x000000003e2fffff], contact BIOS vendor for fixes" ];
        SYSLOG_IDENTIFIER = [ "kernel" ];
      }
      {
        MESSAGE = [ "x86/cpu: SGX disabled by BIOS." ];
        SYSLOG_IDENTIFIER = [ "kernel" ];
      }
      {
        MESSAGE = [ "plymouth-quit.service: Service has no ExecStart=, ExecStop=, or SuccessAction=. Refusing." ];
        SYSLOG_IDENTIFIER = [ "systemd" ];
      }
      {
        MESSAGE = [ "event10: Failed to call EVIOCSKEYCODE with scan code 0x7c, and key code 190: Invalid argument" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        CODE_FILE = [ "../src/modules/module-x11-bell.c" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        MESSAGE = [ "gkr-pam: unable to locate daemon control file" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        MESSAGE = [ "GLib: Source ID 2 was not found when attempting to remove it" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
      {
        MESSAGE = [ "GLib-GObject: g_object_unref: assertion ''G_IS_OBJECT (object)'' failed" ];
        _SELINUX_CONTEXT = [ "kernel" ];
      }
    ];

    xserver = {
      videoDrivers = [ "amdgpu" ];
      xrandrHeads = [
        { output = "DP-1"; primary = true; }
        { output = "DP-3"; }
      ];
      dpi = 175;
      displayManager = {
        gdm.enable = true;
        setupCommands = ''
          ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource "modesetting" NVIDIA-0
          ${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --auto --primary --output DP-3 --auto --right-of DP-1
        '';
      };
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    nix-serve = {
      enable = true;
      openFirewall = true;
      secretKeyFile = "/etc/nixos/secrets/cache-priv-key.pem";
    };
  };

  programs.sway = {
    extraOptions = [ "--unsupported-gpu" ];
    extraSessionCommands = ''
      export WLR_NO_HARDWARE_CURSORS=1
    '';
  };
  virtualisation.docker.enableNvidia = true;
}
