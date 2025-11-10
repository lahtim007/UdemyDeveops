param(
    [string]$AppName = "webAppTest",
    [string]$AppPoolName = "webAppTestPool",
    [string]$AppPoolIdentity = "ApplicationPoolIdentity",
    [string]$SiteName = "webAppTest",
    [string]$PhysicalPath = "E:\inetpub\wwwroot\webapptest",
    [string]$ConnectionString = "Server=localhost;Database=MyAppDB;Trusted_Connection=True;TrustServerCertificate=True;"
)

Import-Module WebAdministration

Write-Host "=== Déploiement de $AppName sur IIS ==="

# 1️⃣ Créer le dossier s’il n’existe pas
if (!(Test-Path $PhysicalPath)) {
    New-Item -Path $PhysicalPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier créé : $PhysicalPath"
}

# 2️⃣ Copier les fichiers publiés
Copy-Item -Path ".\publish\*" -Destination $PhysicalPath -Recurse -Force

# 3️⃣ Créer ou configurer le pool d’applications
if (!(Get-WebAppPoolState -Name $AppPoolName -ErrorAction SilentlyContinue)) {
    New-WebAppPool -Name $AppPoolName
    Write-Host "Pool créé : $AppPoolName"
}

# Configurer l’identité du pool
if ($AppPoolIdentity -ne "ApplicationPoolIdentity") {
    Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel.identityType -Value 3
    Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel.userName -Value $AppPoolIdentity
    Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel.password -Value "Password123!"
} else {
    Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel.identityType -Value 4
}

# 4️⃣ Créer le site IIS
if (!(Get-Website | Where-Object { $_.Name -eq $SiteName })) {
    New-Website -Name $SiteName -Port 8081 -PhysicalPath $PhysicalPath -ApplicationPool $AppPoolName
    Write-Host "Site IIS créé : $SiteName"
}

# 5️⃣ Mettre à jour la chaîne de connexion
$appSettings = Join-Path $PhysicalPath "appsettings.json"
if (Test-Path $appSettings) {
    $json = Get-Content $appSettings -Raw | ConvertFrom-Json
    $json.ConnectionStrings.DefaultConnection = $ConnectionString
    $json | ConvertTo-Json -Depth 10 | Set-Content $appSettings -Encoding UTF8
    Write-Host "Chaîne de connexion mise à jour."
}

iisreset
Write-Host "✅ Déploiement terminé sur SRV-STAGING"