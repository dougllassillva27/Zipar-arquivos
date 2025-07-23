# Projeto: Compactador de Backups Automático

## 1. Visão Geral

Este projeto consiste em um script PowerShell (`Zipar backups.ps1`) que automatiza o processo de otimização de backups de bancos de dados.

O script varre recursivamente uma pasta de origem em busca de arquivos de backup (`.bak`), compacta cada um deles em um arquivo `.rar` individual e, após a compressão bem-sucedida, exclui o arquivo `.bak` original para economizar espaço.

Toda a operação é registrada em um arquivo de log diário para fins de auditoria e monitoramento.

## 2. Pré-requisitos

Para que o script funcione corretamente, o servidor deve atender aos seguintes requisitos:

- **Sistema Operacional:** Windows Server 2019 / 2022 (ou superior).
- **PowerShell:** Versão 5.1 ou superior.
- **WinRAR:** O software WinRAR (versão 64-bit) deve estar instalado no seu caminho padrão: `C:\Program Files\WinRAR\`.

## 3. Configuração do Script

Todas as configurações necessárias são feitas diretamente no início do arquivo `Zipar backups.ps1`. Abra o arquivo em um editor de texto para ajustar as seguintes variáveis:

- **`$caminhoRaizDosBackups`**: Define a pasta principal que o script irá verificar em busca de arquivos `.bak`. O script analisará esta pasta e todas as suas subpastas.

  ```powershell
  # Exemplo:
  $caminhoRaizDosBackups = "C:\Arquivos"
  ```

- **`$caminhoExecutorRar`**: Caminho completo para o executável de linha de comando do WinRAR. O padrão já está configurado para uma instalação típica de 64-bit.

  ```powershell
  # Exemplo:
  $caminhoExecutorRar    = "C:\Program Files\WinRAR\Rar.exe"
  ```

- **`$caminhoPastaLogs`**: Define a pasta onde os arquivos de log diários serão salvos. É recomendado usar um caminho local e simples para evitar problemas de permissão. O script criará esta pasta se ela não existir.
  ```powershell
  # Exemplo:
  $caminhoPastaLogs      = "C:\Arquivos\Logs_compressao_bak"
  ```

## 4. Configuração da Tarefa Agendada

Para que o script seja executado automaticamente, siga os passos abaixo para criar uma tarefa no Agendador de Tarefas do Windows.

1.  Abra o **Agendador de Tarefas** (pode ser encontrado no menu Iniciar ou executando `taskschd.msc`).

2.  No painel "Ações" à direita, clique em **"Criar Tarefa..."**.

3.  **Na Aba "Geral":**

    - **Nome:** Dê um nome descritivo para a tarefa. Ex: `Compactador de Backups Diário`.
    - **Opções de segurança:**
      _ Marque a opção **"Executar estando o usuário conectado ou não"**. (Obrigatório para automação de servidor).
      _ Marque a opção **"Executar com privilégios mais altos"**.
      ![Configuração da Aba Geral](https://i.imgur.com/83pZ59C.png)

4.  **Na Aba "Disparadores":**

    - Clique em **"Novo..."**.
    - Configure a frequência da execução. Para uma tarefa diária, selecione **"Diariamente"** e defina um horário em que o servidor tenha baixa carga de trabalho (ex: `22:00:00`).
    - Clique em **OK**.

5.  **Na Aba "Ações":**

    - Clique em **"Novo..."**.
    - **Ação:** Deixe como `Iniciar um programa`.
    - **Programa/script:** Digite `powershell.exe`.
    - **Adicione argumentos (opcional):** Este é o campo mais importante. Copie e cole a linha abaixo, **lembrando de ajustar o caminho para a localização exata do seu script `.ps1`**.
      `   -NoProfile -ExecutionPolicy Bypass -File "F:\Caminho\Para\O\Script\Zipar backups.ps1"` \* **Importante:** Se o caminho para o seu script contiver espaços, as aspas duplas `"` são obrigatórias.
      ![Configuração da Aba Ações](https://i.imgur.com/k2oT5Zz.png)

6.  **Na Aba "Configurações":**

    - Revise as opções. Uma configuração útil é **"Se a tarefa já estiver sendo executada, a seguinte regra será aplicada:"** -> **"Não iniciar uma nova instância"**. Isso evita que a tarefa rode duas vezes caso a execução anterior demore mais que o esperado.

7.  Clique em **OK** para salvar a tarefa. O Windows solicitará a senha do usuário configurado para a execução. Insira a senha para finalizar.

## 5. Verificação

- **Execução Manual:** Para testar, você pode clicar com o botão direito na tarefa recém-criada e selecionar **"Executar"**.
- **Monitoramento:** Após a execução, verifique a pasta de logs (configurada na variável `$caminhoPastaLogs`) para consultar o arquivo de log do dia. Ele conterá o registro detalhado de todos os arquivos compactados e de qualquer erro que possa ter ocorrido.
