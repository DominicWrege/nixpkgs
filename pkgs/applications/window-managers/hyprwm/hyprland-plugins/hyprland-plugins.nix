let
  # shared src for upstream hyprland-plugins repo
  # function generating derivations for all plugins in hyprland-plugins
  hyprland-plugins =
    builtins.mapAttrs
      (
        name: description:
        (
          {
            lib,
            cmake,
            fetchFromGitHub,
            hyprland,
            mkHyprlandPlugin,
          }:
          let
            version = "0.47.0";

            hyprland-plugins-src = fetchFromGitHub {
              owner = "hyprwm";
              repo = "hyprland-plugins";
              rev = "refs/tags/v${version}";
              hash = "sha256-zys4H2zSSIw54ecnYnBh2NUKZQraWD4B7qftuClrXho=";
            };
          in
          mkHyprlandPlugin hyprland {
            pluginName = name;
            inherit version;

            src = "${hyprland-plugins-src}/${name}";
            nativeBuildInputs = [ cmake ];
            meta = {
              homepage = "https://github.com/hyprwm/hyprland-plugins";
              description = "Hyprland ${description} plugin";
              license = lib.licenses.bsd3;
              maintainers = lib.teams.hyprland.members;
              inherit (hyprland.meta) platforms;
            };
          }
        )
      )
      {
        borders-plus-plus = "multiple borders";
        csgo-vulkan-fix = "CS:GO/CS2 Vulkan fix";
        hyprbars = "window title";
        hyprexpo = "workspaces overview";
        hyprtrails = "smooth trails behind moving windows";
        hyprwinwrap = "xwinwrap-like";
      };
in
hyprland-plugins
