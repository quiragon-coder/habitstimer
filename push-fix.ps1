# push-fix.ps1
param(
    [string]$Message = "chore: update project"
)

Write-Host "[INFO] Ajout des fichiers modifiés..."
git add -A

Write-Host "[INFO] Création du commit..."
git commit -m "$Message"

Write-Host "[INFO] Pull (rebase) pour éviter les conflits..."
git pull --rebase origin main

Write-Host "[INFO] Push vers GitHub..."
git push -u origin main

Write-Host "[OK] Terminé ✅"
