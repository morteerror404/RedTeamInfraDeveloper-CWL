#!/bin/bash

# Script para instalação e configuração automatizada de ferramentas de Red Team
# Ferramentas: curl, unzip, tree, Evilginx, Gophish, Pwndrop
# Integração: RedTeamInfraDeveloper-CWL repository
# Autor: Grok 3, adaptado de Manus AI

# --- Variáveis de Configuração ---
EVILGINX_VERSION="3.3.0"
GOPHISH_VERSION="0.12.1"
PWNDROP_VERSION="latest"
REPO_URL="https://github.com/morteerror404/RedTeamInfraDeveloper-CWL.git"
INSTALL_DIR="/opt/redteam_tools"
REPO_DIR="/opt/RedTeamInfraDeveloper-CWL"
APP_DIR="$REPO_DIR/App-web"
PWNDROP_PORT=8080
EVILGINX_PORT=8443
GOPHISH_PORT=3333
PWNDROP_TAR="pwndrop-linux-amd64.tar.gz"

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
        log_error "Este script precisa ser executado como root. Por favor, use sudo."
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_go() {
    log_info "Verificando e instalando Go..."
    if ! command_exists go; then
        GO_LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
        GO_TAR="${GO_LATEST_VERSION}.linux-amd64.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TAR}"

        log_info "Baixando ${GO_TAR}..."
        wget -q --show-progress "${GO_URL}" -O /tmp/${GO_TAR} || log_error "Falha ao baixar Go."
        log_info "Extraindo Go para /usr/local..."
        rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/${GO_TAR} || log_error "Falha ao extrair Go."
        log_info "Configurando variáveis de ambiente para Go..."
        echo "export PATH=\$PATH:/usr/local/go/bin" | tee -a /etc/environment > /dev/null
        export PATH=$PATH:/usr/local/go/bin
        log_info "Go instalado: $(go version)"
    else
        log_info "Go já está instalado: $(go version)"
    fi
}

# --- Início do Script ---
check_root
log_info "Atualizando pacotes do sistema..."
apt update -y && apt upgrade -y || log_info "Falha ao atualizar pacotes, continuando..."

# Instalar dependências básicas
log_info "Instalando curl, unzip e tree..."
apt install -y curl unzip tree || log_error "Falha ao instalar curl, unzip ou tree."

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

log_info "Baixando ${EVILGINX_ZIP}..."
wget -q --show-progress "${EVILGINX_URL}" -O "${INSTALL_DIR}/${EVILGINX_ZIP}" || log_error "Falha ao baixar Evilginx."
log_info "Extraindo Evilginx..."
unzip -o "${INSTALL_DIR}/${EVILGINX_ZIP}" -d "${INSTALL_DIR}/evilginx" || log_error "Falha ao extrair Evilginx."
log_info "Configurando permissões para Evilginx..."
chmod +x "${INSTALL_DIR}/evilginx/evilginx"
setcap cap_net_bind_service=+eip "${INSTALL_DIR}/evilginx/evilginx"

# Configurar Evilginx
log_info "Configurando Evilginx na porta ${EVILGINX_PORT}..."
cat > "${INSTALL_DIR}/evilginx/config.yaml" <<EOF
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

log_info "Baixando ${GOPHISH_ZIP}..."
wget -q --show-progress "${GOPHISH_URL}" -O "${INSTALL_DIR}/${GOPHISH_ZIP}" || log_error "Falha ao baixar Gophish."
log_info "Extraindo Gophish..."
unzip -o "${INSTALL_DIR}/${GOPHISH_ZIP}" -d "${INSTALL_DIR}/gophish" || log_error "Falha ao extrair Gophish."
log_info "Configurando Gophish..."
chmod +x "${INSTALL_DIR}/gophish/gophish"
cat > "${INSTALL_DIR}/gophish/config.json" <<EOF
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
if [ -f "./${PWNDROP_TAR}" ]; then
    PWNDROP_TAR_PATH="./${PWNDROP_TAR}"
elif [ -f "/home/ubuntu/${PWNDROP_TAR}" ]; then
    PWNDROP_TAR_PATH="/home/ubuntu/${PWNDROP_TAR}"
else
    log_error "Arquivo ${PWNDROP_TAR} não encontrado em $(pwd) ou /home/ubuntu."
fi

log_info "Extraindo Pwndrop..."
tar -xzf "${PWNDROP_TAR_PATH}" -C "${INSTALL_DIR}" || log_error "Falha ao extrair Pwndrop."
log_info "Configurando permissões para Pwndrop..."
chmod +x "${INSTALL_DIR}/pwndrop"
mkdir -p "${INSTALL_DIR}/pwndrop/data"
chown -R nobody:nogroup "${INSTALL_DIR}/pwndrop"

# Configurar Pwndrop para servir App-web
log_info "Configurando Pwndrop na porta ${PWNDROP_PORT} para servir App-web..."
cat > "${INSTALL_DIR}/pwndrop/pwndrop.ini" <<EOF
[http]
listen_addr = 0.0.0.0:${PWNDROP_PORT}
webroot = ${APP_DIR}
EOF

# --- Configurar Firewall ---
log_info "Configurando regras de firewall (ufw)..."
apt install -y ufw || log_error "Falha ao instalar ufw."
ufw allow ${PWNDROP_PORT}/tcp comment "Pwndrop HTTP"
ufw allow ${EVILGINX_PORT}/tcp comment "Evilginx HTTP"
ufw allow 53 comment "Evilginx DNS"
ufw allow ${GOPHISH_PORT}/tcp comment "Gophish Admin/Phish"
ufw --force enable

# --- Iniciar Serviços ---
log_info "Iniciando Pwndrop..."
su -s /bin/bash -c "pwndrop -c ${INSTALL_DIR}/pwndrop/pwndrop.ini &" nobody
sleep 2
if pgrep -f "pwndrop" >/dev/null; then
    log_info "Pwndrop iniciado na porta ${PWNDROP_PORT}."
else
    log_error "Falha ao iniciar Pwndrop. Verifique logs em ${INSTALL_DIR}/pwndrop."
fi

log_info "Iniciando Evilginx..."
"${INSTALL_DIR}/evilginx/evilginx" -c "${INSTALL_DIR}/evilginx/config.yaml" &
sleep 2
if pgrep -f "evilginx" >/dev/null; then
    log_info "Evilginx iniciado na porta ${EVILGINX_PORT}."
else
    log_error "Falha ao iniciar Evilginx. Verifique logs."
fi

log_info "Iniciando Gophish..."
cd "${INSTALL_DIR}/gophish"
./gophish &
sleep 2
if pgrep -f "gophish" >/dev/null; then
    log_info "Gophish iniciado na porta ${GOPHISH_PORT}."
else
    log_error "Falha ao iniciar Gophish. Verifique logs em ${INSTALL_DIR}/gophish."
fi
cd -

# --- Finalização ---
log_info "Instalação e configuração concluídas!"
log_info "Ferramentas instaladas em: ${INSTALL_DIR}"
log_info "Acesse sua aplicação via:"
log_info "- Pwndrop (App-web): http://<server-ip>:${PWNDROP_PORT}"
log_info "- Evilginx: https://<server-ip>:${EVILGINX_PORT} (configure phishlets manualmente)"
log_info "- Gophish: http://<server-ip>:${GOPHISH_PORT}/admin"
log_info "Repositório clonado em: ${REPO_DIR}"
log_info "Certifique-se de configurar phishlets (Evilginx) e campanhas (Gophish) conforme necessário."