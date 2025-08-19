Write-Host "Résolution automatique des conflits (on garde la version locale)" -ForegroundColor Cyan

# Lister les fichiers en conflit
$conflicts = git diff --name-only --diff-filter=U

if (-not $conflicts) {
    Write-Host "Aucun conflit détecté."
    exit 0
}

foreach ($file in $conflicts) {
    Write-Host "Conflit détecté dans $file → garder la version locale"
    git checkout --ours -- $file
    git add $file
}

# Continuer le rebase
try {
    git rebase --continue
    Write-Host "Conflits résolus avec ta version locale. Rebase continué." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du rebase. Vérifie manuellement." -ForegroundColor Red
}
