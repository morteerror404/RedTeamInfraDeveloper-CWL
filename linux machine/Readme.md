# Configuração do Servidor Ubuntu
Este repositório contém a configuração de um servidor Ubuntu, incluindo:
- Lista de pacotes instalados (packages.txt)
- Informações do sistema (system_info.txt)
- Serviços em execução (services.txt)
- Arquivos de configuração (config_files/)

## Como recriar o ambiente
1. Instale o Ubuntu.
2. Instale os pacotes listados em packages.txt com:

```bash
sudo dpkg --configure -a
sudo apt update
```

```bash
sudo apt install #pacote
```

3. Copie os arquivos de configuração de config_files/ para /etc/.
4. Reinicie os serviços conforme necessário.

**Nota**: Revise os arquivos de configuração para remover informações sensíveis antes de subir.