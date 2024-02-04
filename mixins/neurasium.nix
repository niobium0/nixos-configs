{
  config,
  hostName,
  lib,
  pkgs,
  ...
}: let
  hostCfg = config;
  containerName = "neurasium";
  agentName = "builder";
  userName = "buildkite-agent-${agentName}";
  uid = 986;
  gid = 982;
in {
  config = {
    containers."${containerName}" = {
      autoStart = true;

      bindMounts = {
        "/secrets/buildkite.pat".hostPath = "/etc/nixos/secrets/buildkite.pat";
        "/secrets/buildkite.token".hostPath = "/etc/nixos/secrets/buildkite.token";
      };

      config = let
        containerCfg = hostCfg.containers."${containerName}".config;
      in {
        networking = {
          firewall = {
            enable = true;
            logRefusedConnections = true;
            checkReversePath = "loose";
          };
          hostName = "${hostName}-${containerName}";
        };

        nix = {
          extraOptions = ''
            extra-experimental-features = nix-command flakes
          '';
          settings.cores = 8;
          settings.max-jobs = 1;
          package = pkgs.nix;
        };

        programs = {
          git = {
            enable = true;
            config = {
              credential.helper = "store";
            };
          };
        };

        services = {
          gerrit = {
            enable = true;
            serverId = "iron-${containerName}";
          };

          buildkite-agents."${agentName}" = {
            hooks.environment = ''
              export PAGER=
            '';
            runtimePackages = [
              pkgs.bash
              pkgs.direnv
              pkgs.git
              pkgs.gnugrep
              pkgs.gnutar
              pkgs.gzip
              (pkgs.writeShellScriptBin "nix-env" ''
                exec ${pkgs.nix}/bin/nix-env "$@"
              '')
              (pkgs.writeShellScriptBin "nix-store" ''
                exec ${pkgs.nix}/bin/nix-store "$@"
              '')
              (pkgs.writeShellScriptBin "nix" ''
                exec ${pkgs.nix}/bin/nix --print-build-logs "$@"
              '')
            ];
            shell = "${pkgs.bash}/bin/bash -euo pipefail -c";
            tokenPath = "/secrets/buildkite.token";
          };
        };

        system.stateVersion = "23.11";

        systemd.services."${userName}" = {
          preStart = ''
            set -euo pipefail
            export BUILDKITE_PAT=$(cat /secrets/buildkite.pat)
            echo \
              "https://neurasium-buildkite-agent:$BUILDKITE_PAT@github.com" \
              > "${containerCfg.services.buildkite-agents.${agentName}.dataDir}/.git-credentials"
          '';
        };

        users = {
          users."${userName}" = {
            inherit uid;
          };
          groups."${userName}" = {
            inherit gid;
          };
        };
      };

      ephemeral = false;
      # hostBridge = bridgeName;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
      privateNetwork = true;
    };

    networking = {
      nat = {
        internalInterfaces = ["ve-+"];
        enable = true;
        enableIPv6 = true;
      };
      useDHCP = lib.mkDefault true;
    };

    users = {
      users.${userName} = {
        inherit uid;
        group = userName;
      };
      groups.${userName} = {
        inherit gid;
      };
    };
  };
}
