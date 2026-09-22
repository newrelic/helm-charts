<#
.SYNOPSIS
    Runs the chart's real Windows Fluent Bit container (image/command/env extracted from `helm
    template` by the calling workflow) on this runner, seeds a marker log line, and asserts via
    NRQL that it reaches New Relic.

    Note: the chart's `kubernetes` filter has no real API server to reach here. Fluent Bit treats
    that as a soft failure (skips k8s metadata enrichment, doesn't crash), so it doesn't affect
    this test's marker/crash/persistence checks.

.PARAMETER Image
    Windows image tag to test, extracted from the chart's rendered DaemonSet.
.PARAMETER ConfigDir
    Directory with the rendered fluent-bit.conf + parsers.conf, mounted at C:\fluent-bit\etc.
.PARAMETER ScriptsDir
    Directory with the extracted payload.lua (from the chart's -lua ConfigMap), mounted at
    C:\fluent-bit\scripts. Needed because fluentBitMetrics defaults to "basic", which enables a
    lua filter that requires this script to be present.
.PARAMETER EnvJsonPath
    JSON file of the DaemonSet's env vars, excluding LICENSE_KEY/NODE_NAME/HOSTNAME (those come
    from Kubernetes secretKeyRef/fieldRef in production; this script supplies them itself).
.PARAMETER CommandJsonPath
    JSON file with the DaemonSet's `command` array, checked against docker-compose.windows.yml's
    hardcoded command so the two can't silently drift apart.
.PARAMETER AccountId / ApiKey / LicenseKey
    New Relic test-account credentials (K8S_AGENTS_E2E_* secrets in CI).
.PARAMETER MarkerTag
    Unique per-run tag embedded in the marker log line and the NRQL filter.
#>
param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][string]$ConfigDir,
    [Parameter(Mandatory = $true)][string]$ScriptsDir,
    [Parameter(Mandatory = $true)][string]$EnvJsonPath,
    [Parameter(Mandatory = $true)][string]$CommandJsonPath,
    [Parameter(Mandatory = $true)][string]$AccountId,
    [Parameter(Mandatory = $true)][string]$ApiKey,
    [Parameter(Mandatory = $true)][string]$LicenseKey,
    [Parameter(Mandatory = $true)][string]$MarkerTag,
    [int]$MarkerRetries = 15,
    [int]$MarkerDelaySeconds = 20,
    [int]$HealthWatchIterations = 12,
    [int]$HealthWatchDelaySeconds = 5
)

$ErrorActionPreference = "Stop"

$TestDir = $PSScriptRoot
$WorkDir = Join-Path $TestDir ".windows-e2e-work"
$LogsDir = Join-Path $WorkDir "logs"
$ContainerName = "nr-logging-wine2e"
$ComposeProject = "nrloggingwine2e"
$ComposeFile = Join-Path $TestDir "docker-compose.windows.yml"
$HealthPort = 2020
$Marker = "nr-logging-e2e-windows-marker-$MarkerTag"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Wait-Until {
    param(
        [scriptblock]$Condition,
        [string]$Description,
        [int]$MaxRetries = 10,
        [int]$DelaySeconds = 2
    )
    for ($i = 0; $i -le $MaxRetries; $i++) {
        if (& $Condition) {
            return $true
        }
        Write-Host "Waiting for $Description. Trying again in ${DelaySeconds}s. Try #$i"
        Start-Sleep -Seconds $DelaySeconds
    }
    return $false
}

function Test-ContainerRunning {
    param([string]$Name)
    try {
        $status = docker inspect -f "{{.State.Running}}" $Name 2>$null
        return ($LASTEXITCODE -eq 0) -and ($status.Trim() -eq "true")
    }
    catch {
        return $false
    }
}

function Test-FluentBitHealthy {
    param([int]$Port)
    try {
        $resp = Invoke-WebRequest -Method GET -Uri "http://localhost:$Port/api/v1/health" -UseBasicParsing -TimeoutSec 5
        return $resp.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Get-MarkerCountFromNerdGraph {
    param([string]$Marker)
    $nrql = "SELECT count(*) AS markerCount FROM Log WHERE message LIKE '%$Marker%' SINCE 30 minutes ago"
    $body = @{
        query = "{ actor { account(id: $AccountId) { nrql(query: `"$nrql`") { results } } } }"
    } | ConvertTo-Json -Compress
    try {
        $resp = Invoke-RestMethod -Method POST -Uri "https://api.newrelic.com/graphql" `
            -Headers @{ "Api-Key" = $ApiKey; "Content-Type" = "application/json" } `
            -Body $body -TimeoutSec 15
        if ($resp.errors) {
            Write-Host "NerdGraph returned errors: $($resp.errors | ConvertTo-Json -Depth 5)"
            return 0
        }
        return [int]$resp.data.actor.account.nrql.results[0].markerCount
    }
    catch {
        Write-Host "NerdGraph query failed (will retry): $_"
        return 0
    }
}

function Invoke-Cleanup {
    Write-Step "Cleaning up"
    docker compose -f $ComposeFile -p $ComposeProject down --remove-orphans 2>$null | Out-Null
    docker rm -f $ContainerName 2>$null | Out-Null
    if (Test-Path $WorkDir) { Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue }
}

try {
    Invoke-Cleanup

    Write-Step "Checking the DaemonSet's command hasn't drifted from docker-compose.windows.yml"
    $extractedCommand = (Get-Content $CommandJsonPath -Raw | ConvertFrom-Json) -join " "
    $expectedCommand = "C:\fluent-bit\bin\fluent-bit.exe -c c:\fluent-bit\etc\fluent-bit.conf -e C:\fluent-bit\bin\out_newrelic.dll"
    if ($extractedCommand -ne $expectedCommand) {
        throw "templates/daemonset-windows.yaml's command changed (`"$extractedCommand`") - update the hardcoded command in docker-compose.windows.yml to match."
    }

    Write-Step "Preparing test volumes"
    New-Item -ItemType Directory -Force -Path (Join-Path $LogsDir "containers") | Out-Null
    $logFile = Join-Path $LogsDir "containers\nr-logging-e2e-marker-source.log"
    New-Item -ItemType File -Force -Path $logFile | Out-Null

    Write-Step "Loading extracted DaemonSet env vars from $EnvJsonPath"
    $daemonsetEnv = Get-Content $EnvJsonPath -Raw | ConvertFrom-Json

    Write-Step "Starting the newrelic-logging Windows container (image: $Image)"
    $env:NR_FB_IMAGE = $Image
    $env:CONTAINER_NAME = $ContainerName
    $env:HEALTH_PORT = "$HealthPort"
    $env:CONFIG_DIR = $ConfigDir
    $env:LOGS_DIR = $LogsDir
    $env:SCRIPTS_DIR = $ScriptsDir
    $env:ENDPOINT = $daemonsetEnv.ENDPOINT
    $env:SOURCE = $daemonsetEnv.SOURCE
    $env:LICENSE_KEY = $LicenseKey
    $env:CLUSTER_NAME = $daemonsetEnv.CLUSTER_NAME
    $env:LOG_LEVEL = $daemonsetEnv.LOG_LEVEL
    $env:LOG_PARSER = $daemonsetEnv.LOG_PARSER
    $env:FB_DB = $daemonsetEnv.FB_DB
    $env:FLUENTBIT_PATH = $daemonsetEnv.PATH
    $env:K8S_BUFFER_SIZE = $daemonsetEnv.K8S_BUFFER_SIZE
    $env:K8S_LOGGING_EXCLUDE = $daemonsetEnv.K8S_LOGGING_EXCLUDE
    $env:LOW_DATA_MODE = $daemonsetEnv.LOW_DATA_MODE
    $env:RETRY_LIMIT = $daemonsetEnv.RETRY_LIMIT
    # No real cluster here, so NODE_NAME/HOSTNAME (Kubernetes fieldRef in production) get synthetic values.
    $env:NODE_NAME = "nr-logging-wine2e-node"
    $env:HOSTNAME = "nr-logging-wine2e-pod"
    $env:SEND_OUTPUT_PLUGIN_METRICS = $daemonsetEnv.SEND_OUTPUT_PLUGIN_METRICS
    $env:METRICS_HOST = $daemonsetEnv.METRICS_HOST
    $env:FLUENTBIT_METRICS_TIER = $daemonsetEnv.FLUENTBIT_METRICS_TIER
    $env:LUA_SCRIPT_PATH = $daemonsetEnv.LUA_SCRIPT_PATH
    $env:DAEMONSET_NAME = $daemonsetEnv.DAEMONSET_NAME
    $env:NAMESPACE = $daemonsetEnv.NAMESPACE

    docker compose -f $ComposeFile -p $ComposeProject up -d
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start container $ContainerName from image $Image via docker-compose"
    }

    if (-not (Wait-Until -Condition { Test-ContainerRunning -Name $ContainerName } -Description "container to start" -MaxRetries 10 -DelaySeconds 3)) {
        Write-Host "--- Container logs ---"
        docker logs $ContainerName 2>&1
        throw "Container never reached a running state"
    }

    Write-Step "Writing marker log lines: $Marker"
    1..5 | ForEach-Object {
        Add-Content -Path $logFile -Value "$Marker $(Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')"
        Start-Sleep -Milliseconds 500
    }

    Write-Step "Waiting for the marker to arrive in New Relic (account $AccountId)"
    if (-not (Wait-Until -Condition { (Get-MarkerCountFromNerdGraph -Marker $Marker) -ge 1 } -Description "marker log to arrive in New Relic" -MaxRetries $MarkerRetries -DelaySeconds $MarkerDelaySeconds)) {
        Write-Host "--- Container logs ---"
        docker logs $ContainerName 2>&1
        throw "Marker log never arrived in New Relic within the retry budget"
    }
    Write-Step "Marker log confirmed in New Relic."

    # Regression check for fluent/fluent-bit#11904: Fluent Bit crashed on Windows when
    # HTTP_Server + Health_Check were both enabled (both are on by default in this chart).
    Write-Step "Watching for a regression of fluent/fluent-bit#11904 (HTTP_Server crash) for $($HealthWatchIterations * $HealthWatchDelaySeconds)s"
    $sawHealthyResponse = $false
    for ($i = 0; $i -lt $HealthWatchIterations; $i++) {
        if (-not (Test-ContainerRunning -Name $ContainerName)) {
            Write-Host "--- Container exited. Logs: ---"
            docker logs $ContainerName 2>&1
            throw "Container exited while HTTP_Server was enabled - possible regression of fluent/fluent-bit#11904"
        }
        if (Test-FluentBitHealthy -Port $HealthPort) {
            $sawHealthyResponse = $true
        }
        Start-Sleep -Seconds $HealthWatchDelaySeconds
    }
    if (-not $sawHealthyResponse) {
        throw "Health endpoint at port $HealthPort never responded with 200 - HTTP_Server may not have started correctly"
    }
    Write-Step "No crash after the watch window, with HTTP_Server + Health_Check enabled"

    Write-Step "Checking DB persistence file was created (mirrors fluentBit.windowsDb in the Helm chart)"
    $dbFile = Join-Path $LogsDir "flb_kube.db"
    if (-not (Test-Path $dbFile)) {
        throw "Expected DB persistence file was not created at $dbFile"
    }
    Write-Step "DB persistence file confirmed at $dbFile"

    Write-Step "Success! Marker delivered to New Relic, no HTTP_Server crash, DB persistence confirmed."
    exit 0
}
catch {
    Write-Host "Windows E2E test failed: $_"
    exit 1
}
finally {
    Invoke-Cleanup
}
