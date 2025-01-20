#!/bin/bash

# Caminho para o diretório do programa
PROGRAM_DIR="$HOME/.password_manager"
ALIAS_NAME="password_manager"

# Remove os arquivos e diretórios
echo "Removendo arquivos do programa..."
rm -rf "$PROGRAM_DIR"

# Remove o alias do shell
echo "Removendo alias..."
SHELL_RC="$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] && SHELL_RC="$HOME/.zshrc"

sed -i "/alias $ALIAS_NAME=/d" "$SHELL_RC"

# Atualiza o ambiente do shell
echo "Atualizando o ambiente do shell..."
source "$SHELL_RC"

echo "Desinstalação concluída!"

source $HOME/.bashrc || source $HOME/.zshrc
