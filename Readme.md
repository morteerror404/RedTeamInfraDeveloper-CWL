# RedTeamInfraDeveloper-CWL

Este repositório contém recursos e scripts para auxiliar na configuração de uma infraestrutura de Red Team, focando em ferramentas como Evilginx, Gophish e Pwndrop.

## Visão Geral

O objetivo deste projeto é fornecer um ambiente padronizado e automatizado para a implantação de ferramentas essenciais em operações de Red Team, facilitando o setup e a gestão dessas ferramentas. A automação visa reduzir o tempo de configuração e minimizar erros manuais, permitindo que os operadores se concentrem nas atividades de engajamento.

## Ferramentas Incluídas

Este repositório foca na instalação e configuração das seguintes ferramentas:

- **Evilginx**: Um framework de ataque Man-in-the-Middle (MitM) para phishing de credenciais e cookies de sessão, capaz de contornar a autenticação de dois fatores (2FA).
- **Gophish**: Uma plataforma de código aberto para a criação e gestão de campanhas de phishing, com uma interface web intuitiva para monitoramento em tempo real.
- **Pwndrop**: Um serviço de hospedagem de arquivos auto-implantável, ideal para o envio de payloads e compartilhamento seguro de arquivos em operações de Red Team.

## Como Utilizar

Para configurar e utilizar as ferramentas, siga as instruções abaixo. É altamente recomendável que você leia a documentação completa fornecida (`redteam_tools_documentation.md`) para entender os detalhes de cada ferramenta e as configurações pós-instalação necessárias.

### 1. Script de Instalação Automatizada

Um script shell (`install_redteam_tools.sh`) foi desenvolvido para automatizar o processo de instalação das ferramentas. Este script cuida das dependências, downloads e configurações iniciais.

#### Pré-requisitos

- Sistema Operacional: Debian/Ubuntu (testado em Ubuntu 22.04).
- Privilégios de `root` ou `sudo` para execução do script.
- Conexão com a internet para download das ferramentas.
- O arquivo `pwndrop-linux-amd64.tar.gz` deve estar no mesmo diretório do script ou em `/home/ubuntu/` antes da execução.

#### Passos para Execução

1. **Baixe o script `install_redteam_tools.sh`** para o seu servidor. Se você já tem o arquivo `install_redteam_tools.sh` e `pwndrop-linux-amd64.tar.gz` no seu ambiente, pode pular o download.

```bash
wget https://github.com/morteerror404/RedTeamInfraDeveloper-CWL/blob/main/Machine/tools/install_redteam_tools.sh
# Ou
curl -o install_redteam_tools.sh https://github.com/morteerror404/RedTeamInfraDeveloper-CWL/blob/main/linux%20machine/install_redteam_tools.sh
```

2. **Conceda permissões de execução** ao script:

   ```bash
   chmod +x install_redteam_tools.sh
   ```

3. **Execute o script com privilégios de root**:

   ```bash
   sudo ./install_redteam_tools.sh
   ```

   O script irá:
   - Atualizar os pacotes do sistema.
   - Instalar o Go (se necessário).
   - Baixar e instalar Evilginx, Gophish e Pwndrop no diretório `/opt/redteam_tools/`.
   - Configurar as permissões iniciais.

### 2. Configurações Pós-Instalação e Uso das Ferramentas

Após a execução do script, as ferramentas estarão instaladas em `/opt/redteam_tools/`. No entanto, cada ferramenta requer configurações adicionais para ser totalmente operacional e adaptada às suas necessidades de campanha.

#### Evilginx

Para iniciar e configurar o Evilginx, navegue até o diretório de instalação e execute o binário. A configuração de `phishlets`, domínios e certificados SSL é feita através da interface de linha de comando do Evilginx.

```bash
cd /opt/redteam_tools/evilginx
sudo ./evilginx
```

Consulte a [documentação oficial do Evilginx](https://help.evilginx.com/pro/) para detalhes sobre como criar e gerenciar suas campanhas de phishing, incluindo a configuração de domínios e certificados SSL.

#### Gophish

O Gophish é executado a partir de seu diretório de instalação. Antes de iniciar, você pode precisar editar o arquivo `config.json` para ajustar as portas de escuta, credenciais de administrador e configurações de banco de dados. Se nenhum `config.json` for fornecido, o Gophish gerará um padrão na primeira execução.

```bash
cd /opt/redteam_tools/gophish
./gophish
```

Após iniciar o Gophish, acesse a interface web (geralmente `https://<seu_ip>:3333` ou `http://<seu_ip>:80`) para criar e gerenciar suas campanhas de phishing. A [documentação do Gophish](https://docs.getgophish.com/user-guide/) oferece guias detalhados sobre como usar a plataforma.

#### Pwndrop

O Pwndrop é uma ferramenta simples de usar. Navegue até o diretório de instalação e execute o binário. A configuração de senhas e outras opções de segurança pode ser feita através de variáveis de ambiente ou arquivos de configuração específicos da ferramenta, conforme a documentação do Pwndrop.

```bash
cd /opt/redteam_tools/pwndrop
./pwndrop
```

Para mais informações sobre o Pwndrop e suas funcionalidades, consulte o [repositório oficial do Pwndrop no GitHub](https://github.com/kgretzky/pwndrop).

## Como Subir a Aplicação (Serviços)

Para garantir que as ferramentas Evilginx, Gophish e Pwndrop sejam executadas de forma persistente e iniciem automaticamente com o sistema, é altamente recomendável configurá-las como serviços do `systemd`.

### Exemplo de Serviço Systemd (Gophish)

Você pode criar um arquivo de serviço `systemd` para cada ferramenta. Abaixo está um exemplo para o Gophish. Adapte-o para Evilginx e Pwndrop conforme necessário.

1. **Crie o arquivo de serviço**: Por exemplo, `/etc/systemd/system/gophish.service`

   ```ini
   [Unit]
   Description=Gophish Phishing Framework
   After=network.target

   [Service]
   Type=simple
   ExecStart=/opt/redteam_tools/gophish/gophish
   WorkingDirectory=/opt/redteam_tools/gophish
   Restart=always
   User=root # Ou um usuário não-root se configurado para isso

   [Install]
   WantedBy=multi-user.target
   ```

2. **Recarregue o daemon do systemd**:

   ```bash
   sudo systemctl daemon-reload
   ```

3. **Inicie o serviço**:

   ```bash
   sudo systemctl start gophish
   ```

4. **Habilite o serviço para iniciar no boot**:

   ```bash
   sudo systemctl enable gophish
   ```

Repita este processo para Evilginx e Pwndrop, ajustando `ExecStart`, `WorkingDirectory` e `Description` conforme a ferramenta.