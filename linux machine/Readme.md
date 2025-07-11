# Documentação: Configuração do Servidor Ubuntu para Operações de Red Team

## Introdução
Este repositório contém a configuração de um servidor Ubuntu Server projetado para operações de Red Team, incluindo a instalação automatizada de ferramentas específicas (Evilginx, Gophish e Pwndrop) e a documentação dos recursos instalados no sistema. O objetivo é fornecer um ambiente reproduzível para campanhas de segurança ofensiva, com scripts, configurações e instruções claras para recriação.

O script `install_redteam_tools.sh` automatiza a instalação das ferramentas mencionadas, enquanto arquivos adicionais (como `packages.txt`, `system_info.txt` e `services.txt`) documentam o estado do sistema para facilitar a replicação do ambiente.

**Data**: 11 de Julho de 2025  
**Autor**: Manus AI

## Ferramentas e Recursos Instalados

### Ferramentas de Red Team
As seguintes ferramentas foram instaladas usando o script `install_redteam_tools.sh`:

- **Evilginx**:
  - **Descrição**: Framework de ataque Man-in-the-Middle (MitM) para phishing de credenciais e cookies de sessão, com suporte a bypass de autenticação de dois fatores (2FA). Atua como proxy reverso para interceptar tráfego.
  - **Versão Instalada**: 3.3.0
  - **Diretório de Instalação**: `/opt/redteam_tools/evilginx`
  - **Referência**: [Evilginx GitHub](https://github.com/kgretzky/evilginx2)

- **Gophish**:
  - **Descrição**: Framework de phishing de código aberto com interface web para criar, gerenciar e rastrear campanhas de phishing.
  - **Versão Instalada**: 0.12.1
  - **Diretório de Instalação**: `/opt/redteam_tools/gophish`
  - **Referência**: [Gophish User Guide](https://docs.getgophish.com/user-guide/)

- **Pwndrop**:
  - **Descrição**: Serviço de hospedagem de arquivos auto-implantável para Red Team, ideal para entrega de payloads ou compartilhamento seguro via HTTP/WebDAV.
  - **Versão Instalada**: Fornecida localmente via `pwndrop-linux-amd64.tar.gz`
  - **Diretório de Instalação**: `/opt/redteam_tools/pwndrop`
  - **Referência**: [Pwndrop GitHub](https://github.com/kgretzky/pwndrop)

### Outros Recursos do Sistema
- **Pacotes Instalados**: Listados em `packages.txt`, gerado com:
  ```bash
  apt list --installed > packages.txt
  ```
- **Informações do Sistema**: Detalhes do sistema operacional, kernel e hardware, salvos em `system_info.txt`:
  - Versão do Ubuntu: Obtida com `lsb_release -a`
  - Kernel: Obtido com `uname -a`
  - Hardware (CPU, memória, disco): Obtidos com `lscpu`, `free -h` e `df -h`
- **Serviços em Execução**: Listados em `services.txt` com:
  ```bash
  systemctl list-units --type=service --state=running > services.txt
  ```
- **Arquivos de Configuração**: Copiados para `/opt/redteam_tools/config_files` (ex.: `/etc/nginx`, `/etc/apache2`, `/etc/ssh/sshd_config`, se aplicável).

## Pré-requisitos
- **Sistema Operacional**: Ubuntu Server (baseado em Debian).
- **Privilégios**: Acesso `root` ou permissões para usar `sudo`.
- **Dependências**:
  - Conexão à internet para baixar pacotes e binários.
  - Arquivo `pwndrop-linux-amd64.tar.gz` no diretório `/home/ubuntu/` (ou ajustado no script).
  - Linguagem Go (instalada automaticamente pelo script para o Evilginx).

## Estrutura do Repositório
Após a execução do script e a coleta de informações, o repositório terá a seguinte estrutura:

```
/meu-servidor/
├── install_redteam_tools.sh  # Script de instalação das ferramentas
├── packages.txt              # Lista de pacotes instalados
├── system_info.txt           # Informações do sistema (OS, kernel, hardware)
├── services.txt              # Lista de serviços em execução
├── config_files/             # Arquivos de configuração do sistema
│   ├── nginx/               # Configurações do Nginx (se aplicável)
│   ├── apache2/             # Configurações do Apache (se aplicável)
│   ├── sshd_config          # Configuração do SSH
│   └── ...                  # Outros arquivos de configuração
├── README.md                # Esta documentação
└── .gitignore               # Arquivo para excluir dados sensíveis
```

## Como Configurar o Ambiente

### 1. Preparar o Servidor
- Instale o Ubuntu Server (verifique a versão em `system_info.txt` para compatibilidade).
- Certifique-se de que o sistema tem acesso à internet e privilégios de `root`.

### 2. Coletar Informações do Sistema
Para recriar o ambiente, execute os seguintes comandos para documentar os recursos instalados:
```bash
# Lista de pacotes instalados
sudo apt list --installed > packages.txt

# Informações do sistema
lsb_release -a > system_info.txt
uname -a >> system_info.txt
lscpu >> system_info.txt
free -h >> system_info.txt
df -h >> system_info.txt

# Serviços em execução
systemctl list-units --type=service --state=running > services.txt

# Arquivos de configuração
mkdir config_files
sudo cp -r /etc/nginx /etc/apache2 /etc/ssh/sshd_config config_files/ 2>/dev/null
```

### 3. Baixar e Executar o Script de Instalação
- Baixe o script `install_redteam_tools.sh` :
  ```bash
  wget https://github.com/morteerror404/RedTeamInfraDeveloper-CWL/blob/main/linux%20machine/install_redteam_tools.sh
  ```
- Torne o script executável:
  ```bash
  chmod +x install_redteam_tools.sh
  ```
- Coloque o arquivo `pwndrop-linux-amd64.tar.gz` em `/home/ubuntu/`.
- Execute o script com privilégios de `root`:
  ```bash
  sudo ./install_redteam_tools.sh
  ```

O script realiza as seguintes ações:
- Atualiza os pacotes do sistema (`apt update && apt upgrade`).
- Cria o diretório `/opt/redteam_tools`.
- Instala o Go (dependência do Evilginx).
- Baixa e instala Evilginx (v3.3.0) em `/opt/redteam_tools/evilginx`.
- Configura permissões para Evilginx (`setcap`).
- Baixa e instala Gophish (v0.12.1) em `/opt/redteam_tools/gophish`.
- Extrai Pwndrop em `/opt/redteam_tools/pwndrop`.

### 4. Configurações Pós-Instalação
- **Evilginx**: Configure `phishlets`, domínios e certificados SSL na interface de linha de comando. Consulte a [documentação oficial](https://github.com/kgretzky/evilginx2).
- **Gophish**: Edite o arquivo `config.json` em `/opt/redteam_tools/gophish` para ajustar portas, credenciais e banco de dados. Um `config.json` padrão é gerado na primeira execução.
- **Pwndrop**: Configure senhas e opções de segurança via variáveis de ambiente ou arquivos de configuração.
- **Arquivos de Configuração**: Copie os arquivos de `config_files/` para `/etc/` e ajuste conforme necessário:
```bash
sudo cp -r config_files/* /etc/
sudo systemctl restart nginx apache2 ssh
```

### 5. Instalar Pacotes Adicionais
Reinstale os pacotes listados em `packages.txt`:
```bash
sudo dpkg --configure -a
sudo apt update
xargs -a packages.txt sudo apt install -y
```

## Subir para o GitHub

### 1. Criar o Repositório Local
- Crie uma pasta para o repositório:
  ```bash
  mkdir meu-servidor
  cd meu-servidor
  ```
- Mova os arquivos gerados:
```bash
mv ../install_redteam_tools.sh .
mv ../packages.txt .
mv ../system_info.txt .
mv ../services.txt .
mv ../config_files .
```

- Crie um `.gitignore` para excluir dados sensíveis:
```bash
echo "*.key
*.pem
config_files/shadow
config_files/passwd
config_files/*.conf" > .gitignore
```

- Inicialize o Git:
```bash
git init
git add .
git commit -m "Configuração inicial do servidor Ubuntu com ferramentas de Red Team"
```

### 2. Criar e Subir para o GitHub
- Crie um repositório no GitHub (ex.: `meu-servidor-config`).
- Vincule o repositório local:
```bash
git remote add origin https://github.com/seu-usuario/meu-servidor-config.git
```
- Suba os arquivos:
```bash
git push -u origin master
```

## Solução de Problemas

- **Erro no `dpkg` ou `apt`**: Se `apt list --installed` ou `dpkg --list` falhar, tente:
  ```bash
  sudo dpkg --configure -a
  sudo apt update
  sudo apt install --reinstall apt dpkg
  ```
- **"Script precisa ser executado como root"**: Use `sudo ./install_redteam_tools.sh`.
- **Falha no download de Evilginx/Gophish**: Verifique as URLs no script e atualize as variáveis `EVILGINX_VERSION` ou `GOPHISH_VERSION` se necessário.
- **Pwndrop não encontrado**: Confirme que `pwndrop-linux-amd64.tar.gz` está em `/home/ubuntu/`.
- **Permissões do Evilginx**: Se houver erros de porta, verifique o `setcap`:
  ```bash
  sudo setcap 'cap_net_bind_service=+ep' /opt/redteam_tools/evilginx/evilginx
  ```

## Referências
- [Evilginx GitHub](https://github.com/kgretzky/evilginx2)
- [Gophish User Guide](https://docs.getgophish.com/user-guide/)
- [Pwndrop GitHub](https://github.com/kgretzky/pwndrop)