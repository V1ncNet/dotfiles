{ config, ... }:

{
  launchd.agents.appearance = {
    enable = true;
    waitForNixStore = false;
    config = {
      ProgramArguments = [ "/usr/bin/osascript" "-l" "JavaScript" "${./appearance.js}" ];
      StartInterval = 60;
      RunAtLoad = true;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/appearance.log";
    };
  };
}
