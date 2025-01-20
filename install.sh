#!/bin/bash

# Caminho para o diretório do programa
PROGRAM_DIR="$HOME/.password_manager"
SCRIPT_NAME="password_manager"
ALIAS_NAME="password_manager"

# Verifica dependências
echo "Verificando dependências..."
for cmd in dialog openssl; do
    if ! command -v $cmd &>/dev/null; then
        echo "Erro: '$cmd' não está instalado."
        echo "Instale-o e execute novamente o instalador."
        exit 1
    fi
done

# Cria o diretório do programa
echo "Instalando no diretório: $PROGRAM_DIR"
mkdir -p "$PROGRAM_DIR/data"

# Copia os arquivos para o diretório do programa
cp "$SCRIPT_NAME" "$PROGRAM_DIR/"
touch "$PROGRAM_DIR/data/passwords.enc"

# Configura um alias no ~/.bashrc ou ~/.zshrc
echo "Configurando alias..."
SHELL_RC="$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "alias $ALIAS_NAME=" "$SHELL_RC"; then
    echo "alias $ALIAS_NAME='bash $PROGRAM_DIR/$SCRIPT_NAME'" >>"$SHELL_RC"
    echo "Alias configurado em $SHELL_RC."
else
    echo "Alias já configurado."
fi

# Atualiza o ambiente do shell
echo "Atualizando o ambiente do shell..."
source "$SHELL_RC"

# Configuração inicial do programa
echo "Configurando o programa..."
read -sp "Crie sua senha mestre: " master_password
echo ""
echo "Senha mestre configurada com sucesso!"

# Salva a senha mestre criptografada
echo -n "$master_password" | openssl enc -aes-256-cbc -salt -out "$PROGRAM_DIR/data/master.enc" -pass pass:"$master_password"

echo "Instalação concluída! Você pode usar o programa com o comando '$ALIAS_NAME'."

