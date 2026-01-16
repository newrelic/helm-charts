{{/*
Expand the name of the chart.
*/}}
{{- define "job-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "job-manager.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "job-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allows to override the appVersion to use.
*/}}
{{- define "job-manager.appVersion" -}}
{{- default .Chart.AppVersion .Values.appVersionOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allows overriding of the job-manager Service hostname
*/}}
{{- define "job-manager.hostname" -}}
{{- $name := default "job-manager" (index .Values "global" "hostnameOverride") -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Add internalApiKey directly or retrieve from a Kubernetes Secret
*/}}
{{- define "job-manager.internalApiKey" }}
{{- if .Values.global.internalApiKey -}}
value: {{ .Values.global.internalApiKey | quote }}
{{- else if .Values.global.internalApiKeySecretName -}}
valueFrom:
  secretKeyRef:
    name: {{ .Values.global.internalApiKeySecretName }}
    key: internalApiKey
{{- else -}}
{{- required ".Values.global.internalApiKey or .Values.global.internalApiKeySecretName must be set!" nil }}
{{- end -}}
{{- end }}

{{/*
Ensures that proxy port is set if proxy host is set.
*/}}
{{- define "job-manager.apiProxyHost" }}
{{- if .Values.jobManager.apiProxyHost -}}
{{- if .Values.jobManager.apiProxyPort -}}
- name: BROKER_API_PROXY_HOST
  value: {{ .Values.jobManager.apiProxyHost | quote }}
{{- else -}}
{{- required ".Values.jobManager.apiProxyPort must be set if .Values.jobManager.apiProxyHost is set!" nil }}
{{- end -}}
{{- end }}
{{- end }}

{{/*
Ensures that proxy host is set if proxy port is set.
*/}}
{{- define "job-manager.apiProxyPort" }}
{{- if .Values.jobManager.apiProxyPort -}}
{{- if .Values.jobManager.apiProxyHost -}}
- name: BROKER_API_PROXY_PORT
  value: {{ .Values.jobManager.apiProxyPort | quote }}
{{- else -}}
{{- required ".Values.jobManager.apiProxyHost must be set if .Values.jobManager.apiProxyPort is set!" nil }}
{{- end -}}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "job-manager.labels" -}}
helm.sh/chart: {{ include "job-manager.chart" . }}
{{ include "job-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "job-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "job-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod annotations
*/}}
{{- define "job-manager.podAnnotations" -}}
{{- if or .Values.appArmorProfileName .Values.annotations -}}
annotations:
{{- if .Values.appArmorProfileName }}
  container.apparmor.security.beta.kubernetes.io/{{ .Chart.Name }}: localhost/{{ .Values.appArmorProfileName }}
{{- end }}
{{- range $key, $val := .Values.annotations }}
  {{ $key }}: {{ $val | quote }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Add locationKey directly or retrieve from a Kubernetes Secret
*/}}
{{- define "job-manager.locationKey" }}
{{- if .Values.jobManager.location.key -}}
value: {{ .Values.jobManager.location.key | quote }}
{{- else if .Values.jobManager.location.keySecretName -}}
valueFrom:
  secretKeyRef:
    name: {{ .Values.jobManager.location.keySecretName  }}
    key: locationKey
{{- else -}}
{{- required ".Values.jobManager.location.key or .Values.jobManager.location.keySecretName must be set!" nil }}
{{- end -}}
{{- end }}

{{/*
Validate location configuration (PUBLIC NR-hosted locations ONLY)
*/}}
{{- define "job-manager.validateLocation" -}}
{{- $location := .Values.jobManager.location -}}

{{/* This chart is ONLY for public NR-hosted locations */}}
{{/* Validate required fields */}}
{{- if not $location.name -}}
{{- fail "jobManager.location.name is required (e.g., 'us-east-1-public', 'eu-west-1-public')" -}}
{{- end -}}

{{/* Validate associated workloads */}}
{{- if not $location.associatedWorkloads -}}
{{- fail "jobManager.location.associatedWorkloads must be specified" -}}
{{- end -}}

{{/* Validate no ping-runtime in serverless */}}
{{- range $location.associatedWorkloads -}}
{{- if contains "ping-runtime" . -}}
{{- fail (printf "Unsupported workload '%s'. Serverless PUBLIC locations do not support ping-runtime. Only node-api-runtime and node-browser-runtime are supported." .) -}}
{{- end -}}
{{- end -}}

{{/* Validate region tag for production deployments */}}
{{- if not $location.tags.region -}}
{{- fail "jobManager.location.tags.region is required (e.g., 'us-east-1', 'eu-west-1')" -}}
{{- end -}}
{{- end -}}

{{/*
Validate runtime configuration matches associated workloads
*/}}
{{- define "job-manager.validateRuntimes" -}}
{{- $apiEnabled := index .Values "node-api-runtime" "enabled" -}}
{{- $browserEnabled := index .Values "node-browser-runtime" "enabled" -}}
{{- $associated := .Values.jobManager.location.associatedWorkloads -}}

{{/* Validate at least one runtime is enabled */}}
{{- if not (or $apiEnabled $browserEnabled) -}}
{{- fail "At least one runtime (node-api-runtime or node-browser-runtime) must be enabled" -}}
{{- end -}}

{{/* Validate enabled runtimes match NGEP associatedWorkloads */}}
{{- if $apiEnabled -}}
{{- $found := false -}}
{{- range $associated -}}
{{- if contains "node-api-runtime" . -}}
{{- $found = true -}}
{{- end -}}
{{- end -}}
{{- if not $found -}}
{{- fail "node-api-runtime is enabled but no 'node-api-runtime' workload found in location.associatedWorkloads" -}}
{{- end -}}
{{- end -}}

{{- if $browserEnabled -}}
{{- $found := false -}}
{{- range $associated -}}
{{- if contains "node-browser-runtime" . -}}
{{- $found = true -}}
{{- end -}}
{{- end -}}
{{- if not $found -}}
{{- fail "node-browser-runtime is enabled but no 'node-browser-runtime' workload found in location.associatedWorkloads" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate location labels for pods and resources
*/}}
{{- define "job-manager.locationLabels" -}}
newrelic.com/location-name: {{ .Values.jobManager.location.name | quote }}
newrelic.com/region: {{ .Values.jobManager.location.tags.region | quote }}
{{- if .Values.jobManager.location.tags.provider }}
newrelic.com/provider: {{ .Values.jobManager.location.tags.provider | quote }}
{{- end }}
{{- if .Values.jobManager.location.tags.environment }}
newrelic.com/environment: {{ .Values.jobManager.location.tags.environment | quote }}
{{- end }}
{{- end -}}

{{/*
Add vsePassphrase directly or retrieve from a Kubernetes Secret
*/}}
{{- define "job-manager.vsePassphrase" }}
{{- if or .Values.jobManager.vsePassphrase .Values.jobManager.vsePassphraseSecretName -}}
{{- if .Values.jobManager.vsePassphrase -}}
- name: VSE_PASSPHRASE
  value: {{ .Values.jobManager.vsePassphrase | quote }}
{{- else if .Values.jobManager.vsePassphraseSecretName -}}
- name: VSE_PASSPHRASE
  valueFrom:
    secretKeyRef:
      name: {{ .Values.jobManager.vsePassphraseSecretName  }}
      key: vsePassphrase
{{- end -}}
{{- end -}}
{{- end }}


{{/*
Create the name of the volume to associate to the job manager pod
*/}}
{{- define "job-manager.volumeName" -}}
sjm-volume
{{- end -}}

{{/*
Create the name of the PersistentVolumeClaim to use if Helm is generating one
*/}}
{{- define "job-manager.defaultClaimName" -}}
sjm-pvc
{{- end -}}

{{/*
Use either the provided PersistentVolumeClaim name or the default PVC name
*/}}
{{- define "job-manager.claimName" -}}
  {{ if (.Values.global.persistence).existingClaimName }}
  {{- (.Values.global.persistence).existingClaimName -}}
  {{ else }}
  {{- include "job-manager.defaultClaimName" . -}}
  {{ end }}
{{- end -}}

{{/*
Config map name to be used when user provides user-defined variable file contents
*/}}
{{- define "job-manager.configMapName" -}}
sjm-config
{{- end -}}

{{/*
Mount path for user defined variables directory
*/}}
{{- define "job-manager.userDefinedVariablesPath" -}}
{{ "/var/lib/newrelic/serverless/variables/" }}
{{- end -}}

{{/*
Mount path for custom node modules directory
*/}}
{{- define "job-manager.customNodeModulesPath" -}}
{{ "/var/lib/newrelic/serverless/modules/" }}
{{- end -}}

{{/*
yaml for User Defined Variables volume mount
*/}}
{{- define "job-manager.userDefinedVarMount" -}}
- mountPath: {{ include "job-manager.userDefinedVariablesPath" . | quote }}
  {{- if (.Values.jobManager.userDefinedVariables).userDefinedFile }}
  name: {{ include "job-manager.configMapName" . | quote -}}
  {{ else }}
  name: {{ include "job-manager.volumeName" . | quote }}
  {{ end }}
  {{ if (.Values.jobManager.userDefinedVariables).userDefinedPath }}
  subPath: {{ .Values.jobManager.userDefinedVariables.userDefinedPath | quote }}
  {{ end }}
{{- end -}}

{{/*
yaml for Custom Node Modules volume mount
*/}}
{{- define "job-manager.customNodeModulesMount" -}}
- mountPath: {{ include "job-manager.customNodeModulesPath" . | quote }}
  name: {{ include "job-manager.volumeName" . | quote }}
  subPath: {{ .Values.global.customNodeModules.customNodeModulesPath  | quote }}
{{- end -}}

{{/*
Define the optional volume mounts for the job manager
*/}}
{{- define "job-manager.volumeMounts" -}}
{{- if or (.Values.jobManager.userDefinedVariables).userDefinedPath (.Values.jobManager.userDefinedVariables).userDefinedFile -}}
{{ include "job-manager.userDefinedVarMount" . }}
{{- end -}}
{{ if (.Values.global.customNodeModules).customNodeModulesPath }}
{{ include "job-manager.customNodeModulesMount" . }}
{{- end -}}
{{- end -}}

{{/*
Define whether to mount volumes for the job manager
*/}}
{{- define "job-manager.toMount" -}}
  {{ if or (include "job-manager.toMountUserDefinedVars" .) (include "job-manager.toMountCustomNodeModules" .) }}
  {{ end }}
{{- end -}}

{{/*
Define whether to mount custom node modules volume
*/}}
{{- define "job-manager.toMountCustomNodeModules" -}}
  {{ if (.Values.global.customNodeModules).customNodeModulesPath }}
  {{ end }}
{{- end -}}

{{/*
Define whether to mount user-defined vars volume
*/}}
{{- define "job-manager.toMountUserDefinedVars" -}}
  {{ if or (.Values.jobManager.userDefinedVariables).userDefinedPath (.Values.jobManager.userDefinedVariables).userDefinedFile }}
  {{ end }}
{{- end -}}

{{/*
Define whether to generate a PVC for the job manager. Checks whether the user has already provided an existing PVC name and if not,
whether they've provided an existing PV name.
*/}}
{{- define "job-manager.generatePVC" -}}
  {{ if and (not (.Values.global.persistence).existingClaimName) (.Values.global.persistence).existingVolumeName }}
  {{ end }}
{{- end -}}

{{/*
Calculates the terminationGracePeriodSeconds.
In order to prevent data-loss the grace period should be configured to be > job timeout, which is 240s by
default
*/}}
{{- define "job-manager.terminationGracePeriodSeconds" -}}
{{- $checkTimeout := default 240 .Values.global.checkTimeout -}}
{{- printf "%d" (add $checkTimeout 20) -}}
{{- end -}}

{{/*
Calculates the sum of parallelism of the ephemeral runtimes to configure the job manager parking lot
*/}}
{{- define "job-manager.runtimeParallelism" -}}
{{- $browserParallelism := default 1 (index .Values "node-browser-runtime" "parallelism") -}}
{{- $apiParallelism := default 1 (index .Values "node-api-runtime" "parallelism") -}}
{{- printf "%d" (add $browserParallelism $apiParallelism) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "job-manager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "job-manager.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}