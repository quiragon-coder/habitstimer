# Script PowerShell pour mettre à jour GitHub
param(
    [string]$message = "update"
)

Write-Host "➡️ Sauvegarde du projet sur GitHub avec le message : $message" -ForegroundColor Cyan

# Nettoyer et récupérer les dépendances
flutter clean
flutter pub get

# Vérifier si des fichiers ont changé
git status

# Ajouter tous les fichiers
git add .

# Faire un commit avec le message passé en paramètre
git commit -m "$message"

# Pousser sur la branche main
git push origin main

Write-Host "✅ Code poussé avec succès !" -ForegroundColor Green
