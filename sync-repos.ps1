#!/usr/bin/env pwsh
# sync-repos.ps1 - Sincroniza repositorios publico y privado

param(
    [Parameter(Mandatory=$true)]
    [string]$message,    
    [switch]$public
)

Write-Host "[MSG] Mensaje: $message" -ForegroundColor Cyan

# PASO 1: Commit local
Write-Host "`n[1/3] Preparando cambios..." -ForegroundColor Cyan

git add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error en git add" -ForegroundColor Red
    exit 1
}

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "[INFO] Sin cambios para commitear" -ForegroundColor Gray
    exit 0
}

git commit -m "$message"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error en commit" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Commit creado" -ForegroundColor Green

# PASO 2: Push a repositorio PRIVADO
Write-Host "`n[2/3] Sincronizando privado..." -ForegroundColor Cyan

git push private main
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error en push a privado" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Privado sincronizado" -ForegroundColor Green

# PASO 3: Push a repositorio PUBLICO (solo si -public)
if ($public) {
    Write-Host "`n[3/3] Sincronizando publico..." -ForegroundColor Cyan
    
    $profileFile = "profiles/github_profile_readme.md"
    if (-not (Test-Path $profileFile)) {
        Write-Host "[ERROR] No se encontro $profileFile" -ForegroundColor Red
        exit 1
    }

    $profileContent = Get-Content $profileFile -Raw
    
    # Crear rama temporal
    git checkout --orphan public-sync 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        git branch -D public-sync 2>&1 | Out-Null
        git checkout --orphan public-sync 2>&1 | Out-Null
    }

    # Limpiar directorio
    git rm -rf . 2>&1 | Out-Null
    
    # Crear README.md con contenido del profile
    Set-Content -Path "README.md" -Value $profileContent -Encoding UTF8
    
    # Commit y push
    git add README.md
    git commit -m "$message" 2>&1 | Out-Null
    git push -f public public-sync:main
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Error en push a publico" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Publico sincronizado" -ForegroundColor Green
    
    # Volver a main
    git checkout main 2>&1 | Out-Null
    git branch -D public-sync 2>&1 | Out-Null
} else {
    Write-Host "`n[3/3] [SKIP] Publico no sincronizado" -ForegroundColor Gray
}

Write-Host "`n[DONE] Sincronizacion completada" -ForegroundColor Green
Write-Host "   Privado: [OK]" -ForegroundColor Green
if ($public) {
    Write-Host "   Publico: [OK]" -ForegroundColor Green
} else {
    Write-Host "   Publico: [SKIP]" -ForegroundColor Gray
}
