# ChanIPTV

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Roku](https://img.shields.io/badge/Platform-Roku-662D91.svg)](https://developer.roku.com/)
[![Language: BrightScript](https://img.shields.io/badge/Language-BrightScript-blue.svg)](https://developer.roku.com/docs/references/brightscript-language-reference/)

**ChanIPTV** é um player M3U/M3U8 simples e limpo para Roku, feito com BrightScript + SceneGraph. O usuário informa **sua própria lista** nas configurações e o app organiza por categorias, exibe logos, permite buscar, favoritar e trocar canais pelo controle remoto.

## ✨ Funcionalidades

- **Lista 100% pelo usuário** – Sem listas pré-carregadas. Você adiciona a URL da sua própria lista M3U/M3U8.
- **Navegação por categorias** – Agrupa automaticamente pelos grupos da lista.
- **Busca de canais** – Filtre pelo nome do canal.
- **Favoritos** – Salvos localmente no Roku.
- **Logotipos com fallback** – Usa `tvg-logo` quando disponível, caso contrário exibe iniciais.
- **Filtro adulto** – Ativado por padrão para ocultar canais/grupos com indícios adultos.
- **Player prático** – Troca de canal com ←/→, favoritar com `*` e voltar com `Back`.
- **Interface em Português (BR)** – Pensada para uso direto na TV.
- **Performance** – Renderização incremental da grade para listas com milhares de canais.

## 📸 Interface

- Tela inicial vazia orientando a adicionar a URL em Ajustes
- Grade de categorias e canais com foco limpo
- Player com informações do canal e atalhos intuitivos

*(Sem prints aqui, mas é fácil testar por sideload na sua Roku.)*

## 🛠️ Tecnologias

- [BrightScript](https://developer.roku.com/docs/references/brightscript-language-reference/)
- [Roku SceneGraph (RSG)](https://developer.roku.com/docs/developer-program/core-concepts/scenegraph/)
- [roUrlTransfer](https://developer.roku.com/docs/references/brightscript/components/roUrlTransfer/) para download das listas
- [BrighterScript](https://brighterscript.com/) para validação/transpilação

## 🚀 Testando localmente (Sideload)

1. Ative o **Developer Mode** na sua Roku (`Home > Settings > System > Advanced system settings > Developer options`) e anote o IP + senha.
2. Clone este repositório:

   ```bash
   git clone https://github.com/SEU-USUARIO/ChanIPTV.git
   cd ChanIPTV
   ```

3. Gere o pacote `.zip`:

   **PowerShell**
   ```powershell
   .\tools\Build.ps1
   ```

   **pwsh (PowerShell 7+)**
   ```pwsh
   ./tools/Build.ps1
   ```

4. Abra `http://IP_DA_SUA_ROKU` no navegador, faça login com `rokudev` + senha e envie `ChanIPTV.zip`.
5. Abra o app **ChanIPTV** na sua Roku e adicione sua URL em `Ajustes > URL da lista`.

## 🧪 Validando com BrighterScript

Caso queira validar o código antes de empacotar:

```bash
npx --yes brighterscript --project bsconfig.json --diagnostic-level warn
```

## ⚠️ Avisos importantes

- **Direitos autorais** – Este aplicativo **não hospeda, armazena, grava ou distribui** qualquer conteúdo. Os canais, logotipos e nomes pertencem aos seus respectivos proprietários.
- **Listas fornecidas pelo usuário** – O app não vem com nenhuma lista. Você é responsável por utilizar listas que tenha permissão para acessar.
- **Roku Channel Store** – Apps que facilitem o acesso a conteúdo protegido podem ser rejeitados pela Roku. Este repositório é voltado principalmente para **uso pessoal/sideload**.
- **Somente HTTP/HTTPS** – Apenas URLs com `http://` ou `https://` são aceitas.
- **Uso por sua conta e risco** – Utilize de acordo com as leis aplicáveis ao seu país.

## 📄 Licença

Este projeto está sob a licença [MIT](LICENSE). Sinta-se livre para estudar, modificar e usar para fins pessoais.

## 🤝 Contribuições

Pull requests são bem-vindos. Caso encontre algum bug ou tenha sugestões de melhoria, abra uma [Issue](../../issues).
