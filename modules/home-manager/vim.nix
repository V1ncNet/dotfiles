{ pkgs, ... }:

let
  personalVimFiles = pkgs.linkFarm "vim-personal" {
    "spell/de.utf-8.spl" = pkgs.fetchurl {
      url = "https://ftp.nluug.nl/pub/vim/runtime/spell/de.utf-8.spl";
      hash = "sha256-c8cQfqM5hWzb6SHeuSpFk5xN5uucByYdobndGfaDo9E=";
    };
    "spell/de.utf-8.sug" = pkgs.fetchurl {
      url = "https://ftp.nluug.nl/pub/vim/runtime/spell/de.utf-8.sug";
      hash = "sha256-E9Ds+Shj2J72DNSopesqWhOg6Pm6jRxqvkerqFcUqUg=";
    };
    "after/ftplugin/gitcommit.vim" = pkgs.writeText "gitcommit.vim" ''
      setlocal spell spelllang=de_de,en
      setlocal shiftwidth=2 tabstop=2 softtabstop=2
    '';
    "after/ftplugin/gitrebase.vim" = pkgs.writeText "gitrebase.vim" ''
      nnoremap <buffer> <CR> <Cmd>Cycle<CR>
    '';
  };
in
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
      personalVimFiles
    ];

    extraConfig = ''
      set backspace=indent,eol,start
      set autoindent expandtab tabstop=4 shiftwidth=4

      filetype plugin indent on

      call mkdir(expand('~/.vim/spell'), 'p')
      set spellfile=~/.vim/spell/personal.utf-8.add

      syntax enable
      colorscheme dim

      " Re-query the terminal background when focus returns, so 'background'
      " follows the light/dark appearance
      autocmd FocusGained * if !empty(&t_RB) | call echoraw(&t_RB) | endif
    '';
  };
}
