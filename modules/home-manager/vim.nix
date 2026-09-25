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
      fzf-vim
      vim-dim
      vim-nix
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
      colorscheme dim

      " Re-query the terminal background when focus returns, so 'background'
      " follows the light/dark appearance
      autocmd FocusGained * if !empty(&t_RB) | call echoraw(&t_RB) | endif
    '';
  };
}
