{
  programs.fzf = {
    defaultOptions = [
      "--color=16,fg+:-1:bold,bg+:-1,gutter:-1"
      "--gutter=' '"
    ];

    fileWidget.options = [
      "--preview '[ -d {} ] && ls -A --color=always {} || bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };
}
