{ lib, config, inputs, ... }:

let
  home = config.home.homeDirectory;
  executable = source: { inherit source; executable = true; };
  rules = inputs.agent-rules;
in
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/claude-code-defaults.nix
    ../../modules/openspec-config.nix
    ../../modules/unslop-skill.nix
  ];

  home = {
    username = "agent";
    homeDirectory = "/home/agent";
    stateVersion = "25.05";

    file = {
      ".claude/CLAUDE.md".source = "${rules}/claude/CLAUDE.md";
      ".claude/superpowers.md".source = "${rules}/claude/superpowers.md";
      ".agents/AGENTS.md".source = "${rules}/agents/AGENTS.md";
      ".claude/statusline.sh" = executable ./claude/statusline.sh;
      ".claude/hooks/require-agent-model.sh" = executable ./claude/hooks/require-agent-model.sh;

      ".ssh/allowed_signers".text = ''
        ${config.programs.git.settings.user.email} namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRNHjoQmjkg8cRd/i4PWlxXu63aAnCfNLPw0iDBe0Yg agent@juno
      '';
    };
  };

  programs.git = {
    package = null;
    settings = {
      user.signingKey = "${home}/.ssh/id_ed25519.pub";
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "${home}/.ssh/allowed_signers";
      };
      commit.gpgsign = true;
      credential."https://github.com".helper = "!gh auth git-credential";
      url."https://github.com/".insteadOf = [ "git@github.com:" "ssh://git@github.com/" ];
    };
  };

  claudeCode.defaults = {
    model = "opus";
    effortLevel = "medium";
    advisorModel = "opus";
    modelSettings."claude-opus-5-5".effortLevel = "high";
    hooks.PreToolUse = [{
      matcher = "Agent";
      hooks = [{ type = "command"; command = "~/.claude/hooks/require-agent-model.sh"; }];
    }];
    statusLine = { type = "command"; command = "~/.claude/statusline.sh"; };
    enabledPlugins = {
      "frontend-design@claude-plugins-official" = true;
      "superpowers@claude-plugins-official" = true;
      "code-review@claude-plugins-official" = true;
      "skill-creator@claude-plugins-official" = true;
      "github@claude-plugins-official" = true;
      "claude-md-management@claude-plugins-official" = true;
      "feature-dev@claude-plugins-official" = true;
      "claude-code-setup@claude-plugins-official" = true;
      "playwright@claude-plugins-official" = true;
      "andrej-karpathy-skills@karpathy-skills" = true;
      "ponytail@ponytail" = true;
    };
    extraKnownMarketplaces = {
      karpathy-skills.source = { source = "github"; repo = "forrestchang/andrej-karpathy-skills"; };
      ponytail.source = { source = "github"; repo = "DietrichGebert/ponytail"; };
    };
  };

  systemd.user.enable = false;
  programs.man.enable = false;
  xdg.mime.enable = false;
  manual.manpages.enable = false;

  assertions = [
    {
      assertion = lib.all (package: package.name == "hm-session-vars.sh") config.home.packages
        && config.systemd.user.services == { }
        && config.systemd.user.timers == { };
      message = "agent@juno manages files only, packages and services belong to NixOS";
    }
  ];
}
