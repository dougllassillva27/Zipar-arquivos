<#
.SYNOPSIS
    Script para automatizar a compressão de arquivos de backup (.bak) para o formato .rar,
    excluindo os arquivos originais após a compressão bem-sucedida.

.NOTES
    Autor: Douglas Silva
    Versão: 2.0
    Data: 22/07/2025
#>

# Força a codificação de saída do CONSOLE para UTF-8 para exibir acentos corretamente.
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- INÍCIO DAS CONFIGURAÇÕES ---
$caminhoRaizDosBackups = "C:\Arquivos"
$caminhoExecutorRar    = "C:\Program Files (x86)\WinRAR\Rar.exe"
$caminhoPastaLogs      = "C:\Arquivos"
$nomeArquivoLog        = "Compressao_Backups_$(Get-Date -Format 'yyyy-MM-dd').log"
$caminhoArquivoLogCompleto = Join-Path -Path $caminhoPastaLogs -ChildPath $nomeArquivoLog
# --- FIM DAS CONFIGURAÇÕES ---

# --- FUNÇÃO DE LOG (VERSÃO FINAL COM OUT-FILE) ---
function Escrever-Log {
    param([string]$Mensagem)
    try {
        $pastaDoLog = Split-Path $caminhoArquivoLogCompleto -Parent
        if (-not (Test-Path -Path $pastaDoLog)) {
            New-Item -ItemType Directory -Path $pastaDoLog -Force | Out-Null
        }
        $mensagemComData = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Mensagem"
        
        # **MUDANÇA FINAL** Usando Out-File com -Append, que é o método mais robusto no PowerShell 5.1 para encoding.
        $mensagemComData | Out-File -FilePath $caminhoArquivoLogCompleto -Encoding utf8 -Append

        Write-Host $mensagemComData
    }
    catch {
        Write-Warning "FALHA CRÍTICA AO ESCREVER NO LOG: $($_.Exception.Message)"
    }
}

# --- VERIFICAÇÃO DE PRÉ-REQUISITOS ---
Escrever-Log "--- Início da execução do script de compressão (v2.0) ---"

if (-not (Test-Path -Path $caminhoExecutorRar -PathType Leaf)) {
    Escrever-Log "ERRO CRÍTICO: O executável do WinRAR não foi encontrado em `"$caminhoExecutorRar`". Abortando."
    exit
}
if (-not (Test-Path -Path $caminhoRaizDosBackups -PathType Container)) {
    Escrever-Log "ERRO CRÍTICO: O diretório de backups `"$caminhoRaizDosBackups`" não foi encontrado. Abortando."
    exit
}

# --- LÓGICA PRINCIPAL ---
Escrever-Log "Procurando por arquivos .bak em `"$caminhoRaizDosBackups`"..."
$arquivosBakEncontrados = Get-ChildItem -Path $caminhoRaizDosBackups -Filter "*.bak" -Recurse

if ($null -eq $arquivosBakEncontrados) {
    Escrever-Log "Nenhum arquivo .bak encontrado."
} else {
    Escrever-Log "Foram encontrados $($arquivosBakEncontrados.Count) arquivo(s) .bak."

    foreach ($arquivoBak in $arquivosBakEncontrados) {
        $caminhoCompletoBak = $arquivoBak.FullName
        $nomeArquivoRar = [System.IO.Path]::ChangeExtension($arquivoBak.Name, ".rar")
        $caminhoCompletoRar = Join-Path -Path $arquivoBak.DirectoryName -ChildPath $nomeArquivoRar

        Escrever-Log "Compactando `"$caminhoCompletoBak`" para `"$caminhoCompletoRar`"..."

        $argumentosRar = "a -ep1 -m5 -inul `"$caminhoCompletoRar`" `"$caminhoCompletoBak`""
        $processo = $null

        try {
            $processo = Start-Process -FilePath $caminhoExecutorRar -ArgumentList $argumentosRar -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop

            if ($null -eq $processo) {
                Escrever-Log "ERRO CRÍTICO: O processo Rar.exe não pôde ser iniciado (retornou nulo)."
            }
            elseif ($processo.ExitCode -eq 0) {
                Escrever-Log "SUCESSO: Arquivo `"$($arquivoBak.Name)`" compactado. Excluindo original..."
                try {
                    Remove-Item -Path $caminhoCompletoBak -Force -ErrorAction Stop
                    Escrever-Log "Arquivo `"$($arquivoBak.Name)`" excluído com sucesso."
                } catch {
                    Escrever-Log "ERRO AO EXCLUIR: Não foi possível excluir `"$($arquivoBak.Name)`". Erro: $($_.Exception.Message)"
                }
            } else {
                Escrever-Log "ERRO NA COMPRESSÃO: Falha ao compactar `"$($arquivoBak.Name)`". Código de saída: $($processo.ExitCode)."
            }
        }
        catch {
            Escrever-Log "ERRO GRAVE NO START-PROCESS: Exceção ao iniciar o Rar.exe. Mensagem: $($_.Exception.Message)"
        }
    }
}

Escrever-Log "--- Fim da execução do script ---"