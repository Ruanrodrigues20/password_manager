#!/bin/bash

# Diretório de instalação
INSTALL_DIR="$HOME/.password_manager"

# Nome do arquivo principal
SCRIPT_NAME="password_manager.sh"

# Verificando se o arquivo existe no diretório atual
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "Erro: Arquivo '$SCRIPT_NAME' não encontrado no diretório atual."
    exit 1
fi

# Criando diretório de instalação, se não existir
mkdir -p "$INSTALL_DIR"

# Copiando o script para o diretório de instalação
cp "$SCRIPT_NAME" "$INSTALL_DIR/"

# Verificando a integridade da cópia
if [ $? -ne 0 ]; then
    echo "Erro ao copiar o arquivo '$SCRIPT_NAME' para '$INSTALL_DIR'."
    exit 1
fi

# Garantindo permissões de execução
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Configurando o alias
ALIAS_COMMAND="alias password_manager='bash $INSTALL_DIR/$SCRIPT_NAME'"
if ! grep -qxF "$ALIAS_COMMAND" ~/.bashrc; then
    echo "$ALIAS_COMMAND" >> ~/.bashrc
    echo "Alias configurado com sucesso."
else
    echo "Alias já configurado."
fi

# Recarregando ambiente do shell
source ~/.bashrc

# Finalizando
echo "Instalação concluída com sucesso! Use 'password_manager' para iniciar."
