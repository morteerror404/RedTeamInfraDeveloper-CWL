#!/bin/bash

# Script para instalação e configuração automatizada de ferramentas de Red Team
# Ferramentas: Evilginx, Gophish, Pwndrop
# Autor: Manus AI

# --- Variáveis de Configuração ---
EVILGINX_VERSION="3.3.0"
GOPHISH_VERSION="0.12.1"
PWNDROP_VERSION="latest" # Usaremos o tar.gz fornecido, que é a versão mais recente

INSTALL_DIR="/opt/redteam_tools"

# --- Funções Auxiliares ---
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Este script precisa ser executado como root. Por favor, use sudo."
        exit 1
    fi
}

install_go() {
    log_info "Verificando e instalando Go..."
    if ! command -v go &> /dev/null; then
        GO_LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
        GO_TAR="${GO_LATEST_VERSION}.linux-amd64.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TAR}"

        log_info "Baixando ${GO_TAR}..."
        wget -q --show-progress "${GO_URL}" -O /tmp/${GO_TAR}
        if [ $? -ne 0 ]; then
            log_error "Falha ao baixar Go. Abortando."
            exit 1
        fi

        log_info "Extraindo Go para /usr/local..."
        rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/${GO_TAR}
        if [ $? -ne 0 ]; then
            log_error "Falha ao extrair Go. Abortando."
            exit 1
        fi

        log_info "Configurando variáveis de ambiente para Go..."
        echo "export PATH=$PATH:/usr/local/go/bin" | tee -a /etc/profile > /dev/null
        echo "export PATH=$PATH:/usr/local/go/bin" | tee -a ~/.bashrc > /dev/null
        source /etc/profile # Recarrega para o script atual
        log_info "Go instalado com sucesso: $(go version)"
    else
        log_info "Go já está instalado: $(go version)"
    fi
}

# --- Início do Script ---
check_root

log_info "Atualizando pacotes do sistema..."
apt update -y && apt upgrade -y
if [ $? -ne 0 ]; then
    log_error "Falha ao atualizar pacotes do sistema. Continuando, mas pode haver problemas."
fi

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# --- Instalação do Evilginx ---
log_info "Iniciando instalação do Evilginx..."
install_go

EVILGINX_ZIP="evilginx-v${EVILGINX_VERSION}-linux-64bit.zip"
EVILGINX_URL="https://github.com/kgretzky/evilginx2/releases/download/v${EVILGINX_VERSION}/${EVILGINX_ZIP}"

log_info "Baixando ${EVILGINX_ZIP}..."
wget -q --show-progress "${EVILGINX_URL}" -O "${INSTALL_DIR}/${EVILGINX_ZIP}"
if [ $? -ne 0 ]; then
    log_error "Falha ao baixar Evilginx. Verifique a URL ou a versão. Abortando."
    exit 1
fi

log_info "Extraindo Evilginx..."
unzip -o "${INSTALL_DIR}/${EVILGINX_ZIP}" -d "${INSTALL_DIR}/evilginx"
if [ $? -ne 0 ]; then
    log_error "Falha ao extrair Evilginx. Abortando."
    exit 1
fi

log_info "Configurando permissões para Evilginx..."
chmod +x "${INSTALL_DIR}/evilginx/evilginx"
# Necessário para permitir que o evilginx use portas privilegiadas (<1024) sem ser root
setcap cap_net_bind_service=+eip "${INSTALL_DIR}/evilginx/evilginx"

log_info "Evilginx instalado em: ${INSTALL_DIR}/evilginx"

# --- Instalação do Gophish ---
log_info "Iniciando instalação do Gophish..."
GOPHISH_ZIP="gophish-v${GOPHISH_VERSION}-linux-64bit.zip"
GOPHISH_URL="https://github.com/gophish/gophish/releases/download/v${GOPHISH_VERSION}/${GOPHISH_ZIP}"

log_info "Baixando ${GOPHISH_ZIP}..."
wget -q --show-progress "${GOPHISH_URL}" -O "${INSTALL_DIR}/${GOPHISH_ZIP}"
if [ $? -ne 0 ]; then
    log_error "Falha ao baixar Gophish. Verifique a URL ou a versão. Abortando."
    exit 1
fi

log_info "Extraindo Gophish..."
unzip -o "${INSTALL_DIR}/${GOPHISH_ZIP}" -d "${INSTALL_DIR}/gophish"
if [ $? -ne 0 ]; then
    log_error "Falha ao extrair Gophish. Abortando."
    exit 1
fi

log_info "Configurando Gophish (config.json)..."
# Exemplo de configuração básica, o usuário pode precisar ajustar
# Assumindo que o config.json do usuário será copiado para o diretório do gophish
# Se o config.json do usuário já existe, ele será usado.
# Caso contrário, um config.json padrão será gerado na primeira execução do gophish.

log_info "Gophish instalado em: ${INSTALL_DIR}/gophish"

# --- Instalação do Pwndrop ---
log_info "Iniciando instalação do Pwndrop..."
PWNDROP_TAR="pwndrop-linux-amd64.tar.gz"
# O usuário forneceu o arquivo localmente, então não vamos baixar do GitHub.
# Vamos assumir que o arquivo pwndrop-linux-amd64.tar.gz está no diretório atual do script.

if [ ! -f "/home/ubuntu/${PWNDROP_TAR}" ]; then
    log_error "Arquivo ${PWNDROP_TAR} não encontrado em /home/ubuntu/. Por favor, coloque-o lá. Abortando."
    exit 1
fi

log_info "Extraindo Pwndrop..."
tar -xzf "/home/ubuntu/${PWNDROP_TAR}" -C "${INSTALL_DIR}"
if [ $? -ne 0 ]; then
    log_error "Falha ao extrair Pwndrop. Abortando."
    exit 1
fi

log_info "Configurando permissões para Pwndrop..."
chmod +x "${INSTALL_DIR}/pwndrop"

log_info "Pwndrop instalado em: ${INSTALL_DIR}/pwndrop"

log_info "Instalação e configuração concluídas!"
log_info "Você pode encontrar as ferramentas em: ${INSTALL_DIR}"
log_info "Lembre-se de configurar os arquivos específicos de cada ferramenta (e.g., config.json do Gophish, phishlets do Evilginx) manualmente após a instalação."


