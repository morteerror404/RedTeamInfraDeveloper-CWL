# Documentação: Script de Instalação de Ferramentas de Red Team

## Introdução
Este documento detalha o script `install_redteam_tools.sh`, projetado para automatizar a instalação e configuração inicial de ferramentas essenciais para operações de Red Team: Evilginx, Gophish e Pwndrop. O objetivo é simplificar o processo de setup, garantindo que as dependências sejam resolvidas e as ferramentas estejam prontas para uso com o mínimo de intervenção manual.

## Ferramentas Incluídas

### Evilginx
Evilginx é um framework de ataque Man-in-the-Middle (MitM) usado para phishing de credenciais e cookies de sessão, permitindo o bypass de autenticação de dois fatores (2FA). Ele atua como um proxy reverso, interceptando o tráfego entre a vítima e o site legítimo, capturando credenciais e tokens de sessão. [1]

**Versão Instalada**: `3.3.0`

### Gophish
Gophish é um framework de phishing de código aberto que facilita a criação e o lançamento de campanhas de phishing. Ele fornece uma interface web intuitiva para gerenciar modelos de e-mail, páginas de destino, usuários e grupos, além de rastrear os resultados das campanhas em tempo real. [2]

**Versão Instalada**: `0.12.1`

### Pwndrop
Pwndrop é um serviço de hospedagem de arquivos auto-implantável, projetado para equipes de Red Team. Ele permite o envio fácil de payloads ou o compartilhamento seguro de arquivos privados via HTTP e WebDAV. É notável por sua simplicidade e por ter poucas dependências, sendo ideal para cenários onde a discrição e a rapidez são cruciais. [3]

**Versão Instalada**: A versão fornecida localmente (`pwndrop-linux-amd64.tar.gz`) será utilizada.

## Pré-requisitos

Para a execução bem-sucedida deste script, o sistema operacional deve ser baseado em Debian/Ubuntu. Além disso, é fundamental que o usuário tenha privilégios de `root` ou possa usar `sudo` para executar comandos com privilégios elevados.

## Como Usar o Script

### 1. Download do Script
Primeiro, baixe o script `install_redteam_tools.sh` para o seu sistema. Você pode fazer isso usando `wget` ou `curl` se ele estiver hospedado em algum lugar, ou copiá-lo diretamente para o seu servidor.

```bash
wget https://github.com/morteerror404/RedTeamInfraDeveloper-CWL/blob/main/linux%20machine/tools/install_redteam_tools.sh # Exemplo, substitua pela URL real
# OU
# Copie o conteúdo do script para um arquivo chamado install_redteam_tools.sh
```

### 2. Tornar o Script Executável
Conceda permissões de execução ao script:

```bash
chmod +x install_redteam_tools.sh
```

### 3. Preparar o Arquivo Pwndrop
O script espera que o arquivo `pwndrop-linux-amd64.tar.gz` esteja no diretório `/home/ubuntu/` (ou no diretório onde o script está sendo executado, se modificado). Certifique-se de que este arquivo esteja presente antes de executar o script.

### 4. Executar o Script
O script **deve ser executado com privilégios de root** devido às operações de instalação de pacotes e configuração de permissões (especialmente para o Evilginx, que precisa se ligar a portas privilegiadas).

```bash
sudo ./install_redteam_tools.sh
```

Durante a execução, o script realizará as seguintes etapas:
- Atualizará os pacotes do sistema (`apt update && apt upgrade`).
- Criará o diretório de instalação `/opt/redteam_tools`.
- Instalará a linguagem Go, se ainda não estiver presente, que é uma dependência para o Evilginx.
- Baixará e extrairá os binários do Evilginx para `/opt/redteam_tools/evilginx`.
- Configurará as permissões necessárias para o Evilginx.
- Baixará e extrairá os binários do Gophish para `/opt/redteam_tools/gophish`.
- Extrairá o Pwndrop para `/opt/redteam_tools/pwndrop`.

## Estrutura de Diretórios Pós-Instalação
Após a execução bem-sucedida do script, as ferramentas serão instaladas no diretório `/opt/redteam_tools` com a seguinte estrutura:

```
/opt/redteam_tools/
├── evilginx/
│   └── evilginx
├── gophish/
│   └── gophish
├── pwndrop/
│   └── pwndrop
└── ... (outros arquivos de instalação temporários)
```

## Configurações Pós-Instalação

É importante notar que este script realiza apenas a instalação inicial e a configuração básica. Algumas ferramentas podem exigir configurações adicionais específicas para o seu ambiente ou campanha. Por exemplo:

- **Gophish**: O arquivo `config.json` dentro do diretório do Gophish pode precisar ser editado para ajustar portas, credenciais de administrador e configurações de banco de dados. O script assume que você pode copiar seu `config.json` personalizado para o diretório do Gophish após a instalação, ou o Gophish gerará um padrão na primeira execução.
- **Evilginx**: A configuração de `phishlets`, domínios e certificados SSL é feita dentro da interface de linha de comando do Evilginx após a sua execução. Consulte a documentação oficial do Evilginx para detalhes sobre como configurar suas campanhas de phishing.
- **Pwndrop**: A configuração do Pwndrop geralmente envolve a definição de senhas e outras opções de segurança, que podem ser feitas através de variáveis de ambiente ou arquivos de configuração específicos da ferramenta.

## Solução de Problemas Comuns

- **"Este script precisa ser executado como root."**: Certifique-se de usar `sudo` ao executar o script: `sudo ./install_redteam_tools.sh`.
- **Falha no Download**: Verifique sua conexão com a internet e se as URLs de download das ferramentas (especialmente Evilginx e Gophish) ainda são válidas. As versões especificadas no script (`EVILGINX_VERSION`, `GOPHISH_VERSION`) podem precisar ser atualizadas se novas versões forem lançadas e as URLs antigas se tornarem inválidas.
- **Arquivo Pwndrop não encontrado**: Confirme se `pwndrop-linux-amd64.tar.gz` está no local esperado pelo script (`/home/ubuntu/` por padrão).
- **Problemas de Permissão (Evilginx)**: O script tenta configurar `setcap` para o Evilginx. Se houver erros relacionados a permissões de porta, verifique se o `setcap` está funcionando corretamente no seu sistema ou se há alguma política de segurança (como SELinux/AppArmor) que esteja bloqueando a operação.

## Referências

[1] Evilginx GitHub Repository: [https://github.com/kgretzky/evilginx2](https://github.com/kgretzky/evilginx2)
[2] Gophish User Guide: [https://docs.getgophish.com/user-guide/](https://docs.getgophish.com/user-guide/)
[3] Pwndrop GitHub Repository: [https://github.com/kgretzky/pwndrop](https://github.com/kgretzky/pwndrop)