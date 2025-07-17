#!/bin/bash

# Script para instalação e configuração automatizada de ferramentas de Red Team
# Ferramentas: curl, unzip, tree, Evilginx, Gophish, Pwndrop
# Integração: RedTeamInfraDeveloper-CWL repository
# Autor: Grok 3, adaptado de Manus AI

# --- Configurações ---
set -e

# Variáveis
EVILGINX_VERSION="3.3.0"
GOPHISH_VERSION="0.12.1"
PWNDROP_VERSION="1.0.1"
REPO_URL="https://github.com/morteerror404/RedTeamInfraDeveloper-CWL.git"
INSTALL_DIR="/opt"
REPO_DIR="${INSTALL_DIR}/RedTeamInfraDeveloper-CWL"
APP_DIR="${REPO_DIR}/App-web"
PWNDROP_PORT=8080
EVILGINX_PORT=8443
GOPHISH_PORT=3333
PWNDROP_TAR="pwndrop-linux-amd64.tar.gz"
PWNDROP_URL="https://github.com/kgretzky/pwndrop/releases/download/${PWNDROP_VERSION}/${PWNDROP_TAR}"

# --- Funções Auxiliares ---
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
    exit 1
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Este script precisa ser executado como root. Use sudo."
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

find_install_dir() {
    local binary_name="$1"
    local binary_path=$(which "$binary_name" 2>/dev/null)
    if [ -n "$binary_path" ]; then
        local install_dir=$(readlink -f "$binary_path" | xargs dirname | xargs dirname)
        if [ -d "$install_dir" ]; then
            echo "$install_dir"
            return
        fi
    fi
    local pid=$(pgrep -f "$binary_name" | head -n 1)
    if [ -n "$pid" ]; then
        local exe_path=$(readlink -f "/proc/$pid/exe")
        local install_dir=$(dirname "$exe_path" | xargs dirname)
        echo "$install_dir"
        return
    fi
    echo ""
}

install_go() {
    log_info "Verificando e instalando Go..."
    if ! command_exists go; then
        GO_LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
        GO_TAR="${GO_LATEST_VERSION}.linux-amd64.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TAR}"
        log_info "Baixando ${GO_TAR}..."
        wget -q --show-progress "${GO_URL}" -O "/tmp/${GO_TAR}" || log_error "Falha ao baixar Go."
        [ -f "/tmp/${GO_TAR}" ] || log_error "Arquivo Go ${GO_TAR} não encontrado."
        log_info "Extraindo Go para /usr/local..."
        rm -rf /usr/local/go && tar -C /usr/local -xzf "/tmp/${GO_TAR}" || log_error "Falha ao extrair Go."
        log_info "Configurando variáveis de ambiente para Go..."
        echo "export PATH=\$PATH:/usr/local/go/bin" | tee -a /etc/environment > /dev/null
        export PATH=$PATH:/usr/local/go/bin
        source /etc/environment
        command_exists go || log_error "Go não está no PATH após instalação."
        log_info "Go instalado: $(go version)"
    else
        log_info "Go já está instalado: $(go version)"
    fi
}

create_systemd_service() {
    local service_name="$1"
    local exec_path="$2"
    local config_path="$3"
    local user="$4"
    local description="$5"
    local service_file="/etc/systemd/system/${service_name}.service"

    log_info "Criando serviço systemd para ${service_name}..."
    cat > "${service_file}" <<EOF
[Unit]
Description=${description}
After=network.target

[Service]
ExecStart=${exec_path} -c ${config_path}
Restart=always
User=${user}
WorkingDirectory=$(dirname ${exec_path})

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "${service_name}"
    systemctl start "${service_name}"
    systemctl is-active --quiet "${service_name}" && log_info "${service_name} iniciado com sucesso." || log_error "Falha ao iniciar ${service_name}."
}

# --- Início do Script ---
check_root
log_info "Atualizando pacotes do sistema..."
apt update -y && apt upgrade -y || log_info "Falha ao atualizar pacotes, continuando..."

# Instalar dependências básicas
log_info "Instalando curl, unzip, tree e ufw..."
apt install -y curl unzip tree ufw || log_error "Falha ao instalar dependências."

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# --- Clonar Repositório ---
log_info "Clonando repositório ${REPO_URL}..."
if [ -d "$REPO_DIR" ]; then
    log_info "Repositório já existe em $REPO_DIR. Atualizando..."
    cd "$REPO_DIR"
    git pull || log_error "Falha ao atualizar repositório."
    cd -
else
    git clone "$REPO_URL" "$REPO_DIR" || log_error "Falha ao clonar repositório."
fi
[ -d "$APP_DIR" ] || log_error "Diretório App-web não encontrado em $REPO_DIR."

# --- Instalação do Evilginx ---
log_info "Iniciando instalação do Evilginx..."
install_go
EVILGINX_ZIP="evilginx-v${EVILGINX_VERSION}-linux-64bit.zip"
EVILGINX_URL="https://github.com/kgretzky/evilginx2/releases/download/v${EVILGINX_VERSION}/${EVILGINX_ZIP}"
EVILGINX_DIR="${INSTALL_DIR}/evilginx"

log_info "Baixando ${EVILGINX_ZIP}..."
wget -q --show-progress "${EVILGINX_URL}" -O "${INSTALL_DIR}/${EVILGINX_ZIP}" || log_error "Falha ao baixar Evilginx."
[ -f "${INSTALL_DIR}/${EVILGINX_ZIP}" ] || log_error "Arquivo Evilginx ${EVILGINX_ZIP} não encontrado."
log_info "Extraindo Evilginx..."
unzip -o "${INSTALL_DIR}/${EVILGINX_ZIP}" -d "${EVILGINX_DIR}" || log_error "Falha ao extrair Evilginx."
log_info "Configurando permissões para Evilginx..."
chmod +x "${EVILGINX_DIR}/evilginx"
setcap cap_net_bind_service=+eip "${EVILGINX_DIR}/evilginx"

# Configurar Evilginx
log_info "Configurando Evilginx na porta ${EVILGINX_PORT}..."
cat > "${EVILGINX_DIR}/config.yaml" <<EOF
server:
  bind_addr: 0.0.0.0
  http_port: ${EVILGINX_PORT}
  dns_port: 53
phishlets:
  enabled: []
EOF

# --- Instalação do Gophish ---
log_info "Iniciando instalação do Gophish..."
GOPHISH_ZIP="gophish-v${GOPHISH_VERSION}-linux-64bit.zip"
GOPHISH_URL="https://github.com/gophish/gophish/releases/download/v${GOPHISH_VERSION}/${GOPHISH_ZIP}"
GOPHISH_DIR="${INSTALL_DIR}/gophish"

log_info "Baixando ${GOPHISH_ZIP}..."
wget -q --show-progress "${GOPHISH_URL}" -O "${INSTALL_DIR}/${GOPHISH_ZIP}" || log_error "Falha ao baixar Gophish."
[ -f "${INSTALL_DIR}/${GOPHISH_ZIP}" ] || log_error "Arquivo Gophish ${GOPHISH_ZIP} não encontrado."
log_info "Extraindo Gophish..."
unzip -o "${INSTALL_DIR}/${GOPHISH_ZIP}" -d "${GOPHISH_DIR}" || log_error "Falha ao extrair Gophish."
log_info "Configurando Gophish..."
chmod +x "${GOPHISH_DIR}/gophish"
cat > "${GOPHISH_DIR}/config.json" <<EOF
{
  "admin_server": {
    "listen_url": "0.0.0.0:${GOPHISH_PORT}",
    "use_tls": false,
    "cert_path": "",
    "key_path": ""
  },
  "phish_server": {
    "listen_url": "0.0.0.0:${GOPHISH_PORT}",
    "use_tls": false,
    "cert_path": "",
    "key_path": ""
  },
  "db_name": "sqlite3",
  "db_path": "gophish.db",
  "migrations_prefix": "db/db_",
  "contact_address": ""
}
EOF

# --- Instalação do Pwndrop ---
log_info "Iniciando instalação do Pwndrop..."
PWNDROP_DIR="${INSTALL_DIR}/pwndrop"
log_info "Baixando ${PWNDROP_TAR}..."
wget -q --show-progress "${PWNDROP_URL}" -O "${INSTALL_DIR}/${PWNDROP_TAR}" || log_error "Falha ao baixar Pwndrop."
[ -f "${INSTALL_DIR}/${PWNDROP_TAR}" ] || log_error "Arquivo Pwndrop ${PWNDROP_TAR} não encontrado."
log_info "Extraindo Pwndrop..."
mkdir -p "${PWNDROP_DIR}"
tar -xzf "${INSTALL_DIR}/${PWNDROP_TAR}" -C "${PWNDROP_DIR}" || log_error "Falha ao extrair Pwndrop."
log_info "Configurando permissões para Pwndrop..."
chmod +x "${PWNDROP_DIR}/pwndrop"
mkdir -p "${PWNDROP_DIR}/data"
chown -R nobody:nogroup "${PWNDROP_DIR}"

# Configurar Pwndrop
log_info "Configurando Pwndrop na porta ${PWNDROP_PORT} para servir App-web..."
cat > "${PWNDROP_DIR}/pwndrop.ini" <<EOF
[http]
listen_addr = 0.0.0.0:${PWNDROP_PORT}
webroot = ${APP_DIR}
EOF

# --- Configurar Firewall ---
log_info "Configurando regras de firewall (ufw)..."
ufw allow ${PWNDROP_PORT}/tcp comment "Pwndrop HTTP"
ufw allow ${EVILGINX_PORT}/tcp comment "Evilginx HTTP"
ufw allow 53 comment "Evilginx DNS"
ufw allow ${GOPHISH_PORT}/tcp comment "Gophish Admin/Phish"
ufw --force enable

# --- Criar Serviços Systemd ---
create_systemd_service "pwndrop" "${PWNDROP_DIR}/pwndrop" "${PWNDROP_DIR}/pwndrop.ini" "nobody" "Pwndrop Web Server"
create_systemd_service "evilginx" "${EVILGINX_DIR}/evilginx" "${EVILGINX_DIR}/config.yaml" "root" "Evilginx Phishing Server"
create_systemd_service "gophish" "${GOPHISH_DIR}/gophish" "${GOPHISH_DIR}/config.json" "root" "Gophish Phishing Framework"

# --- Verificação Final ---
log_info "Verificando status dos serviços..."
for service in pwndrop evilginx gophish; do
    if systemctl is-active --quiet "${service}"; then
        log_info "${service} está rodando."
    else
        log_error "${service} não está rodando. Verifique logs com 'journalctl -u ${service}.service'."
    fi
done

# --- Finalização ---
log_info "Instalação e configuração concluídas!"
log_info "Ferramentas instaladas em: ${INSTALL_DIR}"
log_info "Acesse sua aplicação via:"
log_info "- Pwndrop (App-web): http://<server-ip>:${PWNDROP_PORT}"
log_info "- Evilginx: https://<server-ip>:${EVILGINX_PORT} (configure phishlets manualmente)"
log_info "- Gophish: http://<server-ip>:${GOPHISH_PORT}/admin"
log_info "Repositório clonado em: ${REPO_DIR}"
log_info "Certifique-se de configurar phishlets (Evilginx) e campanhas (Gophish) conforme necessário."
log_info "Logs dos serviços podem ser verificados com: journalctl -u <service>.service"