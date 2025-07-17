#!/bin/bash

# Script para instalação e configuração automatizada de ferramentas de Red Team
# Ferramentas: curl, unzip, tree, Evilginx, Gophish, Pwndrop
# Integração: RedTeamInfraDeveloper-CWL repository
# Autor: Adaptado por OxMorte ou Morteerror404

# --- Configurações ---
set -euo pipefail

# Variáveis (agora usando diretório do usuário)
USER_DIR="$HOME/redteam-tools"
INSTALL_DIR="${USER_DIR}/opt"
REPO_DIR="${USER_DIR}/RedTeamInfraDeveloper-CWL"
APP_DIR="${REPO_DIR}/App-web"
LOG_DIR="${USER_DIR}/logs"

# Portas
PWNDROP_PORT=8080
EVILGINX_PORT=8443
GOPHISH_PORT=3333

# URLs e versões
EVILGINX_VERSION="3.3.0"
GOPHISH_VERSION="0.12.1"
PWNDROP_VERSION="1.0.1"
REPO_URL="https://github.com/morteerror404/RedTeamInfraDeveloper-CWL.git"
PWNDROP_TAR="pwndrop-linux-amd64.tar.gz"
PWNDROP_URL="https://github.com/kgretzky/pwndrop/releases/download/${PWNDROP_VERSION}/${PWNDROP_TAR}"

# --- Funções Auxiliares Melhoradas ---
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1" | tee -a "${LOG_DIR}/installation.log"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1" | tee -a "${LOG_DIR}/installation.log" >&2
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" | tee -a "${LOG_DIR}/installation.log" >&2
    exit 1
}

check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        log_warn "Script está sendo executado como root. Recomendado executar como usuário normal."
        read -p "Deseja continuar? [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_port_available() {
    local port=$1
    local service=$2
    if ss -tulpn | grep -q ":${port} "; then
        log_error "Porta ${port} já está em uso por outro serviço (${service})"
    fi
}

setup_directories() {
    log_info "Criando estrutura de diretórios em ${USER_DIR}"
    mkdir -p \
        "${INSTALL_DIR}" \
        "${LOG_DIR}" \
        "${REPO_DIR}" \
        "${INSTALL_DIR}/evilginx" \
        "${INSTALL_DIR}/gophish" \
        "${INSTALL_DIR}/pwndrop"
}

install_dependencies() {
    log_info "Instalando dependências do sistema..."
    sudo apt update -y
    sudo apt install -y \
        curl \
        unzip \
        tree \
        ufw \
        libcap2-bin \
        git \
        wget \
        sqlite3
}

install_go() {
    log_info "Verificando e instalando Go..."
    if ! command_exists go; then
        GO_LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
        GO_TAR="${GO_LATEST_VERSION}.linux-amd64.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TAR}"
        
        log_info "Baixando ${GO_TAR}..."
        wget -q --show-progress "${GO_URL}" -O "/tmp/${GO_TAR}" || log_error "Falha ao baixar Go."
        
        log_info "Extraindo Go para ${INSTALL_DIR}/go..."
        tar -xzf "/tmp/${GO_TAR}" -C "${INSTALL_DIR}" || log_error "Falha ao extrair Go."
        
        log_info "Configurando PATH para Go..."
        echo "export PATH=\$PATH:${INSTALL_DIR}/go/bin" >> "${USER_DIR}/.bashrc"
        echo "export GOPATH=${INSTALL_DIR}/go" >> "${USER_DIR}/.bashrc"
        source "${USER_DIR}/.bashrc"
        
        command_exists go || log_error "Go não está no PATH após instalação."
        log_info "Go instalado: $(go version)"
    else
        log_info "Go já está instalado: $(go version)"
    fi
}

create_user_service() {
    local service_name="$1"
    local exec_path="$2"
    local config_path="$3"
    local user="$4"
    local description="$5"
    local service_file="${USER_DIR}/.config/systemd/user/${service_name}.service"

    log_info "Criando serviço do usuário para ${service_name}..."
    mkdir -p "${USER_DIR}/.config/systemd/user"
    
    cat > "${service_file}" <<EOF
[Unit]
Description=${description}
After=network.target

[Service]
ExecStart=${exec_path} -c ${config_path}
Restart=always
User=${user}
WorkingDirectory=$(dirname ${exec_path})
Environment="PATH=${INSTALL_DIR}/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="GOPATH=${INSTALL_DIR}/go"

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable "${service_name}"
    systemctl --user start "${service_name}"
    
    if ! systemctl --user is-active --quiet "${service_name}"; then
        log_error "Falha ao iniciar ${service_name}. Verifique com: journalctl --user -u ${service_name}.service"
    fi
}

setup_firewall() {
    log_info "Configurando regras básicas de firewall..."
    sudo ufw allow ${PWNDROP_PORT}/tcp comment "Pwndrop HTTP"
    sudo ufw allow ${EVILGINX_PORT}/tcp comment "Evilginx HTTP"
    sudo ufw allow ${GOPHISH_PORT}/tcp comment "Gophish Admin"
    sudo ufw --force enable
}

# --- Implementação das Instalações ---
install_evilginx() {
    log_info "Instalando Evilginx..."
    check_port_available ${EVILGINX_PORT} "Evilginx"
    check_port_available 53 "Evilginx DNS"

    EVILGINX_ZIP="evilginx-v${EVILGINX_VERSION}-linux-64bit.zip"
    EVILGINX_URL="https://github.com/kgretzky/evilginx2/releases/download/v${EVILGINX_VERSION}/${EVILGINX_ZIP}"
    
    wget -q --show-progress "${EVILGINX_URL}" -O "${INSTALL_DIR}/${EVILGINX_ZIP}" || log_error "Falha ao baixar Evilginx."
    unzip -o "${INSTALL_DIR}/${EVILGINX_ZIP}" -d "${INSTALL_DIR}/evilginx" || log_error "Falha ao extrair Evilginx."
    
    chmod +x "${INSTALL_DIR}/evilginx/evilginx"
    sudo setcap cap_net_bind_service=+ep "${INSTALL_DIR}/evilginx/evilginx"

    # Configuração
    cat > "${INSTALL_DIR}/evilginx/config.yaml" <<EOF
server:
  bind_addr: 127.0.0.1
  http_port: ${EVILGINX_PORT}
  dns_port: 53
phishlets:
  enabled: []
EOF
}

install_gophish() {
    log_info "Instalando Gophish..."
    check_port_available ${GOPHISH_PORT} "Gophish"

    GOPHISH_ZIP="gophish-v${GOPHISH_VERSION}-linux-64bit.zip"
    GOPHISH_URL="https://github.com/gophish/gophish/releases/download/v${GOPHISH_VERSION}/${GOPHISH_ZIP}"
    
    wget -q --show-progress "${GOPHISH_URL}" -O "${INSTALL_DIR}/${GOPHISH_ZIP}" || log_error "Falha ao baixar Gophish."
    unzip -o "${INSTALL_DIR}/${GOPHISH_ZIP}" -d "${INSTALL_DIR}/gophish" || log_error "Falha ao extrair Gophish."
    
    chmod +x "${INSTALL_DIR}/gophish/gophish"

    # Configuração
    cat > "${INSTALL_DIR}/gophish/config.json" <<EOF
{
  "admin_server": {
    "listen_url": "127.0.0.1:${GOPHISH_PORT}",
    "use_tls": true,
    "cert_path": "${INSTALL_DIR}/gophish/gophish_admin.crt",
    "key_path": "${INSTALL_DIR}/gophish/gophish_admin.key"
  },
  "phish_server": {
    "listen_url": "0.0.0.0:80",
    "use_tls": false
  },
  "db_name": "sqlite3",
  "db_path": "gophish.db",
  "migrations_prefix": "db/db_",
  "contact_address": ""
}
EOF

    # Gerar certificados auto-assinados
    openssl req -newkey rsa:2048 -nodes -keyout "${INSTALL_DIR}/gophish/gophish_admin.key" \
        -x509 -days 365 -out "${INSTALL_DIR}/gophish/gophish_admin.crt" \
        -subj "/CN=gophish-admin/O=RedTeam" 2>/dev/null
}

install_pwndrop() {
    log_info "Instalando Pwndrop..."
    check_port_available ${PWNDROP_PORT} "Pwndrop"

    wget -q --show-progress "${PWNDROP_URL}" -O "${INSTALL_DIR}/${PWNDROP_TAR}" || log_error "Falha ao baixar Pwndrop."
    tar -xzf "${INSTALL_DIR}/${PWNDROP_TAR}" -C "${INSTALL_DIR}/pwndrop" || log_error "Falha ao extrair Pwndrop."
    
    chmod +x "${INSTALL_DIR}/pwndrop/pwndrop"
    mkdir -p "${INSTALL_DIR}/pwndrop/data"

    # Configuração
    cat > "${INSTALL_DIR}/pwndrop/pwndrop.ini" <<EOF
[http]
listen_addr = 127.0.0.1:${PWNDROP_PORT}
webroot = ${APP_DIR}
[admin]
listen_addr = 127.0.0.1:8081
initial_username = admin
initial_password = $(openssl rand -hex 16)
EOF
}

clone_repository() {
    log_info "Clonando repositório principal..."
    if [ -d "$REPO_DIR" ]; then
        log_info "Atualizando repositório existente..."
        git -C "$REPO_DIR" pull || log_error "Falha ao atualizar repositório."
    else
        git clone "$REPO_URL" "$REPO_DIR" || log_error "Falha ao clonar repositório."
    fi
    
    [ -d "$APP_DIR" ] || log_error "Diretório App-web não encontrado em $REPO_DIR."
}

setup_services() {
    log_info "Configurando serviços..."
    
    # Evilginx
    create_user_service "evilginx" \
        "${INSTALL_DIR}/evilginx/evilginx" \
        "${INSTALL_DIR}/evilginx/config.yaml" \
        "$USER" \
        "Evilginx Phishing Framework"
    
    # Gophish
    create_user_service "gophish" \
        "${INSTALL_DIR}/gophish/gophish" \
        "${INSTALL_DIR}/gophish/config.json" \
        "$USER" \
        "Gophish Phishing Framework"
    
    # Pwndrop
    create_user_service "pwndrop" \
        "${INSTALL_DIR}/pwndrop/pwndrop" \
        "${INSTALL_DIR}/pwndrop/pwndrop.ini" \
        "$USER" \
        "Pwndrop Web Server"
}

# --- Fluxo Principal ---
main() {
    clear
    echo -e "\033[1;36m=== Instalador de Ferramentas Red Team ===\033[0m"
    echo -e "Diretório de instalação: \033[1;33m${USER_DIR}\033[0m"
    echo
    
    check_root
    setup_directories
    install_dependencies
    install_go
    clone_repository
    
    install_evilginx
    install_gophish
    install_pwndrop
    
    setup_firewall
    setup_services
    
    # Configuração final
    log_info "Configurando ambiente do usuário..."
    echo "alias redteam-env='cd ${USER_DIR} && systemctl --user status'" >> "${USER_DIR}/.bashrc"
    
    # Resumo
    echo -e "\n\033[1;32m=== Instalação Concluída com Sucesso ===\033[0m"
    echo -e "\033[1;33mDiretório de Instalação:\033[0m ${USER_DIR}"
    echo -e "\033[1;33mEndereços de Acesso:\033[0m"
    echo -e "- Pwndrop:    http://localhost:${PWNDROP_PORT} (Proxy reverso recomendado)"
    echo -e "- Gophish:    https://localhost:${GOPHISH_PORT}/admin"
    echo -e "- Evilginx:   https://localhost:${EVILGINX_PORT}"
    echo -e "\n\033[1;33mGerenciamento:\033[0m"
    echo -e "systemctl --user [start|stop|status] [pwndrop|gophish|evilginx]"
    echo -e "\n\033[1;33mLogs:\033[0m journalctl --user -u [serviço].service"
    echo -e "\nRecomendado reiniciar a sessão ou executar: source ~/.bashrc"
}

main