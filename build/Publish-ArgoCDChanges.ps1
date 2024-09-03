param(
    [Parameter()]
    [string]$RepoUrl = $ENV:REPO_URL,

    [Parameter()]   
    [string]$RepoPat = $ENV:REPO_PAT,

    [Parameter()]
    [string]$ArgoCDUser = $ENV:ARGOCD_USER,

    [Parameter()]
    [string]$ArgoCDServer = $ENV:ARGOCD_SERVER,

    [Parameter()]
    [string]$ArgoCDPassword = $ENV:ARGOCD_PASSWORD,

    [Parameter()]
    $SourcesDirectory = $ENV:BUILD_SOURCESDIRECTORY,

    [Parameter()]
    [string]$ApplicationName = $ENV:APPLICATION_NAME,

    [Parameter()]
    [string]$KubernetesNamespace = $ENV:KUBERNETES_NAMESPACE,

    [Parameter()]
    [string]$EnvironmentName =$ENV:ENVIRONMENT_NAME,

    [Parameter()]
    [string]$ImageName = $Env:IMAGE_NAME
)

$TokenRepoUrl = $RepoUrl -replace "https://", "https://x-token-auth:$RepoPat@"

git config --global "url.$TokenRepoUrl.insteadOf" $RepoUrl

$CloneDirectory = Join-Path -Path $SourcesDirectory -ChildPath "argocd"

write-host "Shallow cloning repo $RepoUrl into $CloneDirectory..."

git clone --depth 1 $RepoUrl $CloneDirectory

Push-Location -Path $CloneDirectory

git fetch --tags

#NOTE: Would need to know path conventions in the control repo
$AutomationValuesFile = "$CloneDirectory/src/$ApplicationName/values.$Environment.automation.yaml"

Write-Host "Setting image name $ImageName in file $AutomationValuesFile"

Set-Content -Path $AutomationValuesFile -Value @"
Image: $ImageName
"@

Write-Host "Staging changes..."

git add *
git --no-pager diff --staged
git commit -m "Updating image for application $ApplicationName"

Write-Host "Pushing changes..."

git push -f

Write-Host "Moving Tag $EnvironmentName"

git tag -d $EnvironmentName
git push origin ":refs/tags/$EnvironmentName"
git tag -a $EnvironmentName -m "Moving tag"
git push origin $EnvironmentName

Pop-Location

if (!(Get-Command -Name argocd -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing ArgoCD'
    $version = (Invoke-RestMethod https://api.github.com/repos/argoproj/argo-cd/releases/latest).tag_name
    $url = "https://github.com/argoproj/argo-cd/releases/download/" + $version + "/argocd-windows-amd64.exe"
    $output = "argocd.exe"

    Invoke-WebRequest -Uri $url -OutFile $output
    Set-Alias -Name argocd -Value "./$output"
}

Write-Host "Logging into ArgoCD at $ArgoCDServer"

argocd login $ArgoCDServer --username $ArgoCDUser --password $ArgoCDPassword --insecure

$ArgoCDApp = "$ApplicationName-$KubernetesNamespace"

argocd app get $ArgoCDApp

if ($LASTEXITCODE -ne 0) {
    throw "App $ArgoCDApp Not found"
}


Write-Host "Syncing app $ArgoCDApp"

argocd app sync $ArgoCDApp

Write-Host "Waiting for app $ArgoCDApp to become healthy"

argocd app wait $ArgoCDApp --timeout 30

