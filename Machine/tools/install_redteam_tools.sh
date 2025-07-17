```bash
#!/bin/bash

# Script para configuração de ferramentas de Red Team e integração com RedTeamInfraDeveloper-CWL
# Ferramentas: pwndrop, evilginx
# Autor: Adaptado por OxMorte ou Morteerror404

# Exit on any error
set -euo pipefail

# --- Variáveis ---
USER="$(whoami)"
REPO_URL="https://github.com/morteerror404/RedTeamInfraDeveloper-CWL.git"
REPO_DIR="/opt/RedTeamInfraDeveloper-CWL"
APP_DIR="${REPO_DIR}/App-web"
LOG_DIR="/var/log/redteam"
PWNDROP_PORT=8080
EVILGINX_PORT=8443
GOPHISH_PORT=3333  # Incluído para compatibilidade com script anterior

# --- Funções Auxiliares ---
log_info() {
    mkdir -p "${LOG_DIR}" || { echo -e "\033[1;31m[ERROR]\033[0m Falha ao criar diretório de logs ${LOG_DIR}"; exit 1; }
    echo -e "\033[1;34m[INFO]\033[0m $1" | tee -a "${LOG_DIR}/configure_redteam.log"
}

log_warn() {
    mkdir -p "${LOG_DIR}" || { echo -e "\033[1;31m[ERROR]\033[0m Falha ao criar diretório de logs ${LOG_DIR}"; exit 1; }
    echo -e "\033[1;33m[WARN]\033[0m $1" | tee -a "${LOG_DIR}/configure_redteam.log" >&2
}

log_error() {
    mkdir -p "${LOG_DIR}" || echo -e "\033[1;31m[ERROR]\033[0m Falha ao criar diretório de logs ${LOG_DIR}"
    echo -e "\033[1;31m[ERROR]\033[0m $1" | tee -a "${LOG_DIR}/configure_redteam.log" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_connectivity() {
    log_info "Verificando conectividade com a internet..."
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        log_error "Sem conectividade com a internet. Verifique sua rede."
    fi
}

check_port_available() {
    local port=$1
    local service=$2
    if command_exists ss && ss -tulpn | grep -q ":${port} "; then
        log_error "Porta ${port} já está em uso por outro serviço (${service})"
    elif command_exists netstat && netstat -tulpn 2>/dev/null | grep -q ":${port} "; then
        log_error "Porta ${port} já está em uso por outro serviço (${service})"
    elif command_exists lsof && lsof -i :${port} >/dev/null 2>&1; then
        log_error "Porta ${port} já está em uso por outro serviço (${service})"
    fi
}

check_dns_conflict() {
    log_info "Verificando conflitos na porta 53 (DNS)..."
    if systemctl is-active --quiet systemd-resolved; then
        log_warn "systemd-resolved está ativo. Desativando para evitar conflitos com Evilginx DNS..."
        systemctl disable --now systemd-resolved || log_error "Falha ao desativar systemd-resolved."
    fi
}

find_install_dir() {
    local binary_name="$1"
    local possible_dirs=(
        "/opt/$binary_name"
        "/usr/local/$binary_name"
        "/usr/share/$binary_name"
        "/home/$USER/$binary_name"
    )

    # Try which + readlink
    local binary_path=$(which "$binary_name" 2>/dev/null)
    if [ -n "$binary_path" ]; then
        local install_dir=$(readlink -f "$binary_path" 2>/dev/null | xargs dirname 2>/dev/null | xargs dirname 2>/dev/null)
        if [ -d "$install_dir" ]; then
            echo "$install_dir"
            return
        fi
    fi

    # Check common directories
    for dir in "${possible_dirs[@]}"; do
        if [ -d "$dir" ] && [ -x "$dir/$binary_name" ]; then
            echo "$dir"
            return
        fi
    done

    # Last resort: try to find from process
    local pid=$(pgrep -f "$binary_name" | head -n 1)
    if [ -n "$pid" ]; then
        local exe_path=$(readlink -f "/proc/$pid/exe" 2>/dev/null)
        if [ -n "$exe_path" ]; then
            local install_dir=$(dirname "$exe_path" | xargs dirname 2>/dev/null)
            if [ -d "$install_dir" ]; then
                echo "$install_dir"
                return
            fi
        fi
    fi

    echo ""
}

create_user_service() {
    local service_name="$1"
    local exec_path="$2"
    local config_path="$3"
    local user="$4"
    local description="$5"
    local service_file="/etc/systemd/system/${service_name}.service"

    log_info "Criando serviço do sistema para ${service_name}..."
    mkdir -p "$(dirname "${service_file}")" || log_error "Falha ao criar diretório de serviços systemd."

    cat > "${service_file}" <<EOF
[Unit]
Description=${description}
After=network.target

[Service]
ExecStart=${exec_path} -c ${config_path}
Restart=always
User=${user}
WorkingDirectory=$(dirname ${exec_path})
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "${service_name}"
    systemctl start "${service_name}"

    if ! systemctl is-active --quiet "${service_name}"; then
        log_error "Falha ao iniciar ${service_name}. Verifique com: journalctl -u ${service_name}.service"
    fi
}

# --- Fluxo Principal ---
main() {
    clear
    echo -e "\033[1;36m=== Configurador de Ferramentas Red Team ===\033[0m"
    echo -e "Diretório de instalação: \033[1;33m${REPO_DIR}\033[0m"
    echo

    # Criar diretório de logs
    mkdir -p "${LOG_DIR}" || log_error "Falha ao criar diretório de logs ${LOG_DIR}"

    # Ensure script is run as root
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root. Use sudo."
    fi

    # Check for required tools
    for cmd in git pwndrop evilginx ufw; do
        if ! command_exists "$cmd"; then
            log_error "$cmd is not installed. Please run setup_redteam_tools.sh first."
        fi
    done

    # Verificar dependências adicionais
    log_info "Verificando dependências adicionais..."
    for cmd in curl unzip tree libcap2-bin wget sqlite3 net-tools lsof; do
        if ! command_exists "$cmd"; then
            log_info "Instalando $cmd..."
            apt update -y
            apt install -y "$cmd" || log_error "Falha ao instalar $cmd."
        fi
    done

    # Verificar conectividade
    check_connectivity

    # Verificar portas
    check_port_available ${PWNDROP_PORT} "Pwndrop"
    check_port_available ${EVILGINX_PORT} "Evilginx"
    check_dns_conflict

    # Find installation directories
    PWNDROP_DIR=$(find_install_dir "pwndrop")
    EVILGINX_DIR=$(find_install_dir "evilginx")

    if [ -z "$PWNDROP_DIR" ]; then
        log_error "Could not determine pwndrop installation directory"
    fi
    if [ -z "$EVILGINX_DIR" ]; then
        log_error "Could not determine evilginx installation directory"
    fi

    log_info "Found installations:"
    log_info "- pwndrop: $PWNDROP_DIR"
    log_info "- evilginx: $EVILGINX_DIR"

    # Clone repository
    log_info "Cloning repository..."
    if [ -d "$REPO_DIR" ]; then
        log_info "Repository already exists at $REPO_DIR. Pulling latest changes..."
        cd "$REPO_DIR"
        git pull || log_error "Falha ao atualizar repositório."
        cd -
    else
        git clone "$REPO_URL" "$REPO_DIR" || log_error "Falha ao clonar repositório."
    fi

    # Validate App-web directory
    if [ ! -d "$APP_DIR" ] || [ ! -f "${APP_DIR}/index.html" ]; then
        log_error "App-web directory not found or incomplete in $REPO_DIR."
    fi

    # Configure pwndrop
    log_info "Configuring pwndrop to serve App-web on port $PWNDROP_PORT..."
    PWNDROP_CONFIG="$PWNDROP_DIR/pwndrop.ini"
    if [ -f "$PWNDROP_CONFIG" ]; then
        cp "$PWNDROP_CONFIG" "${PWNDROP_CONFIG}.bak" || log_error "Falha ao criar backup de $PWNDROP_CONFIG."
    fi
    cat > "$PWNDROP_CONFIG" <<EOF
[http]
listen_addr = 0.0.0.0:$PWNDROP_PORT
webroot = $APP_DIR
[admin]
listen_addr = 0.0.0.0:8081
initial_username = admin
initial_password = $(openssl rand -hex 16)
EOF
    chmod 600 "$PWNDROP_CONFIG"
    mkdir -p "$PWNDROP_DIR/data"
    chown -R "${USER}:${USER}" "$PWNDROP_DIR"

    # Configure evilginx
    log_info "Configuring evilginx on port $EVILGINX_PORT..."
    EVILGINX_CONFIG="$EVILGINX_DIR/config.yaml"
    if [ -f "$EVILGINX_CONFIG" ]; then
        cp "$EVILGINX_CONFIG" "${EVILGINX_CONFIG}.bak" || log_error "Falha ao criar backup de $EVILGINX_CONFIG."
    fi
    cat > "$EVILGINX_CONFIG" <<EOF
server:
  bind_addr: 0.0.0.0
  http_port: $EVILGINX_PORT
  dns_port: 53
phishlets:
  enabled: []
EOF
    chmod 600 "$EVILGINX_CONFIG"
    setcap cap_net_bind_service=+ep "$EVILGINX_DIR/evilginx" || log_error "Falha ao configurar permissões para evilginx."

    # Configure services
    create_user_service "pwndrop" \
        "$PWNDROP_DIR/pwndrop" \
        "$PWNDROP_CONFIG" \
        "$USER" \
        "Pwndrop Web Server"

    create_user_service "evilginx" \
        "$EVILGINX_DIR/evilginx" \
        "$EVILGINX_CONFIG" \
        "$USER" \
        "Evilginx Phishing Framework"

    # Configure firewall
    log_info "Configuring firewall rules..."
    ufw allow $PWNDROP_PORT/tcp comment "Pwndrop HTTP"
    ufw allow $EVILGINX_PORT/tcp comment "Evilginx HTTP"
    ufw allow 53 comment "Evilginx DNS"
    ufw --force enable

    # Verify services
    log_info "Verifying services..."
    if systemctl is-active --quiet pwndrop; then
        log_info "pwndrop is running on port $PWNDROP_PORT."
    else
        log_error "pwndrop failed to start. Check logs with: journalctl -u pwndrop.service"
    fi
    if systemctl is-active --quiet evilginx; then
        log_info "evilginx is running on port $EVILGINX_PORT."
    else
        log_error "evilginx failed to start. Check logs with: journalctl -u evilginx.service"
    fi

    # Final summary
    echo -e "\n\033[1;32m=== Configuração Concluída com Sucesso ===\033[0m"
    echo -e "\033[1;33mDiretório do Repositório:\033[0m ${REPO_DIR}"
    echo -e "\033[1;33mEndereços de Acesso:\033[0m"
    echo -e "- Pwndrop:    http://<server-ip>:${PWNDROP_PORT}"
    echo -e "- Evilginx:   https://<server-ip>:${EVILGINX_PORT}"
    echo -e "\n\033[1;33mGerenciamento:\033[0m"
    echo -e "systemctl [start|stop|status] [pwndrop|evilginx]"
    echo -e "\n\033[1;33mLogs:\033[0m journalctl -u [serviço].service"
    echo -e "Ensure you configure evilginx phishlets as needed for your use case."
}

main
