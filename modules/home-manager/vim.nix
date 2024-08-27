{ pkgs, ... }:

{
  # Home Manager Package vim currently fails to install
  # home.packages = [ pkgs.vim ];

  programs.vim = {
    enable = true;
    defaultEditor = true;

    settings = {
      number = true;
    };

    plugins = with pkgs.vimPlugins; [
      dracula-vim
      fzf-vim
      vim-nix
      vim-git
      zoxide-vim
    ];

    extraConfig = ''
      set backspace=indent,eol,start
      set autoindent expandtab tabstop=4 shiftwidth=4

      filetype plugin indent on

      if has('spell')
        autocmd FileType gitcommit setlocal spell
      endif

      syntax enable
    '';
  };
}
