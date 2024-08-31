[CmdletBinding()]
param(
    [Parameter()]
    [string]$ArtifactPath = $Env:ARTIFACT_PATH,

    [string]
    [Parameter()]
    $DockerFilePath = $Env:DOCKERFILE_PATH,

    [Parameter()]
    [string]$DockerImageName = $ENV:DOCKER_IMAGE_NAME,

    [Parameter()]
    [string]$DockerImageTag = $ENV:DOCKER_IMAGE_TAG,

    [Parameter()]
    [string]$GcloudLocation = $ENV:GCLOUD_LOCATION,

    [Parameter()]
    [string]$GcloudProject = $ENV:GCLOUD_PROJECT,

    [Parameter()]
    [string]$GcloudArtifactRegistryRepo = $ENV:GCLOUD_ARTIFACT_REGISTRY_REPO, 

    [string]
    [Parameter()]
    $GcloudAuthKeyFilePath = $ENV:GCLOUD_AUTH_KEY_FILE_PATH
)


$DockerRepoDomain = "$GCloudLocation-docker.pkg.dev"
$ImageTag = "$DockerRepoDomain/$GCloudProject/$GcloudArtifactRegistryRepo/$($DockerImageName):$DockerImageTag"
Write-Host "Full Docker Image Tag is $ImageTag"

$DockerLoginUrl = "https://$DockerRepoDomain"

Get-Content -Path $GcloudAuthKeyFilePath | 
  docker login -u _json_key --password-stdin $DockerLoginUrl

& docker buildx build -t $ImageTag $DockerFilePath --build-arg "artifactStagingPath=$ArtifactPath"

& docker push $ImageTag