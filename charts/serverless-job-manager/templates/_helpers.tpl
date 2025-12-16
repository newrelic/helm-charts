{{/*
Expand the name of the chart.
*/}}
{{- define "serverless-job-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "serverless-job-manager.fullname" -}}
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
{{- define "serverless-job-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allows to override the appVersion to use.
*/}}
{{- define "serverless-job-manager.appVersion" -}}
{{- default .Chart.AppVersion .Values.appVersionOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allows overriding of the serverless-job-manager Service hostname
*/}}
{{- define "serverless-job-manager.hostname" -}}
{{- $name := default "serverless-job-manager" (index .Values "global" "hostnameOverride") -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Add internalApiKey directly or retrieve from a Kubernetes Secret
*/}}
{{- define "serverless-job-manager.internalApiKey" }}
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
{{- define "serverless-job-manager.apiProxyHost" }}
{{- if .Values.serverless.apiProxyHost -}}
{{- if .Values.serverless.apiProxyPort -}}
- name: BROKER_API_PROXY_HOST
  value: {{ .Values.serverless.apiProxyHost | quote }}
{{- else -}}
{{- required ".Values.serverless.apiProxyPort must be set if .Values.serverless.apiProxyHost is set!" nil }}
{{- end -}}
{{- end }}
{{- end }}

{{/*
Ensures that proxy host is set if proxy port is set.
*/}}
{{- define "serverless-job-manager.apiProxyPort" }}
{{- if .Values.serverless.apiProxyPort -}}
{{- if .Values.serverless.apiProxyHost -}}
- name: BROKER_API_PROXY_PORT
  value: {{ .Values.serverless.apiProxyPort | quote }}
{{- else -}}
{{- required ".Values.serverless.apiProxyHost must be set if .Values.serverless.apiProxyPort is set!" nil }}
{{- end -}}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "serverless-job-manager.labels" -}}
helm.sh/chart: {{ include "serverless-job-manager.chart" . }}
{{ include "serverless-job-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "serverless-job-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "serverless-job-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod annotations
*/}}
{{- define "serverless-job-manager.podAnnotations" -}}
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
{{- define "serverless-job-manager.locationKey" }}
{{- if .Values.serverless.locationKey -}}
value: {{ .Values.serverless.locationKey | quote }}
{{- else if .Values.serverless.locationKeySecretName -}}
valueFrom:
  secretKeyRef:
    name: {{ .Values.serverless.locationKeySecretName  }}
    key: locationKey
{{- else -}}
{{- required ".Values.serverless.locationKey or .Values.serverless.locationKeySecretName must be set!" nil }}
{{- end -}}
{{- end }}

{{/*
Add vsePassphrase directly or retrieve from a Kubernetes Secret
*/}}
{{- define "serverless-job-manager.vsePassphrase" }}
{{- if or .Values.serverless.vsePassphrase .Values.serverless.vsePassphraseSecretName -}}
{{- if .Values.serverless.vsePassphrase -}}
- name: VSE_PASSPHRASE
  value: {{ .Values.serverless.vsePassphrase | quote }}
{{- else if .Values.serverless.vsePassphraseSecretName -}}
- name: VSE_PASSPHRASE
  valueFrom:
    secretKeyRef:
      name: {{ .Values.serverless.vsePassphraseSecretName  }}
      key: vsePassphrase
{{- end -}}
{{- end -}}
{{- end }}


{{/*
Create the name of the volume to associate to the serverless job manager pod
*/}}
{{- define "serverless-job-manager.volumeName" -}}
sjm-volume
{{- end -}}

{{/*
Create the name of the PersistentVolumeClaim to use if Helm is generating one
*/}}
{{- define "serverless-job-manager.defaultClaimName" -}}
sjm-pvc
{{- end -}}

{{/*
Use either the provided PersistentVolumeClaim name or the default PVC name
*/}}
{{- define "serverless-job-manager.claimName" -}}
  {{ if (.Values.global.persistence).existingClaimName }}
  {{- (.Values.global.persistence).existingClaimName -}}
  {{ else }}
  {{- include "serverless-job-manager.defaultClaimName" . -}}
  {{ end }}
{{- end -}}

{{/*
Config map name to be used when user provides user-defined variable file contents
*/}}
{{- define "serverless-job-manager.configMapName" -}}
sjm-config
{{- end -}}

{{/*
Mount path for user defined variables directory
*/}}
{{- define "serverless-job-manager.userDefinedVariablesPath" -}}
{{ "/var/lib/newrelic/serverless/variables/" }}
{{- end -}}

{{/*
Mount path for custom node modules directory
*/}}
{{- define "serverless-job-manager.customNodeModulesPath" -}}
{{ "/var/lib/newrelic/serverless/modules/" }}
{{- end -}}

{{/*
yaml for User Defined Variables volume mount
*/}}
{{- define "serverless-job-manager.userDefinedVarMount" -}}
- mountPath: {{ include "serverless-job-manager.userDefinedVariablesPath" . | quote }}
  {{- if (.Values.serverless.userDefinedVariables).userDefinedFile }}
  name: {{ include "serverless-job-manager.configMapName" . | quote -}}
  {{ else }}
  name: {{ include "serverless-job-manager.volumeName" . | quote }}
  {{ end }}
  {{ if (.Values.serverless.userDefinedVariables).userDefinedPath }}
  subPath: {{ .Values.serverless.userDefinedVariables.userDefinedPath | quote }}
  {{ end }}
{{- end -}}

{{/*
yaml for Custom Node Modules volume mount
*/}}
{{- define "serverless-job-manager.customNodeModulesMount" -}}
- mountPath: {{ include "serverless-job-manager.customNodeModulesPath" . | quote }}
  name: {{ include "serverless-job-manager.volumeName" . | quote }}
  subPath: {{ .Values.global.customNodeModules.customNodeModulesPath  | quote }}
{{- end -}}

{{/*
Define the optional volume mounts for the serverless job manager
*/}}
{{- define "serverless-job-manager.volumeMounts" -}}
{{- if or (.Values.serverless.userDefinedVariables).userDefinedPath (.Values.serverless.userDefinedVariables).userDefinedFile -}}
{{ include "serverless-job-manager.userDefinedVarMount" . }}
{{- end -}}
{{ if (.Values.global.customNodeModules).customNodeModulesPath }}
{{ include "serverless-job-manager.customNodeModulesMount" . }}
{{- end -}}
{{- end -}}

{{/*
Define whether to mount volumes for the serverless job manager
*/}}
{{- define "serverless-job-manager.toMount" -}}
  {{ if or (include "serverless-job-manager.toMountUserDefinedVars" .) (include "serverless-job-manager.toMountCustomNodeModules" .) }}
  {{ end }}
{{- end -}}

{{/*
Define whether to mount custom node modules volume
*/}}
{{- define "serverless-job-manager.toMountCustomNodeModules" -}}
  {{ if (.Values.global.customNodeModules).customNodeModulesPath }}
  {{ end }}
{{- end -}}

{{/*
Define whether to mount user-defined vars volume
*/}}
{{- define "serverless-job-manager.toMountUserDefinedVars" -}}
  {{ if or (.Values.serverless.userDefinedVariables).userDefinedPath (.Values.serverless.userDefinedVariables).userDefinedFile }}
  {{ end }}
{{- end -}}

{{/*
Define whether to generate a PVC for the serverless job manager. Checks whether the user has already provided an existing PVC name and if not,
whether they've provided an existing PV name.
*/}}
{{- define "serverless-job-manager.generatePVC" -}}
  {{ if and (not (.Values.global.persistence).existingClaimName) (.Values.global.persistence).existingVolumeName }}
  {{ end }}
{{- end -}}

{{/*
Calculates the terminationGracePeriodSeconds.
In order to prevent data-loss the grace period should be configured to be > serverless job timeout, which is 240s by
default
*/}}
{{- define "serverless-job-manager.terminationGracePeriodSeconds" -}}
{{- $checkTimeout := default 240 .Values.global.checkTimeout -}}
{{- printf "%d" (add $checkTimeout 20) -}}
{{- end -}}

{{/*
Calculates the sum of parallelism of the ephemeral runtimes to configure the job manager parking lot
*/}}
{{- define "serverless-job-manager.runtimeParallelism" -}}
{{- $browserParallelism := default 1 (index .Values "node-browser-runtime" "parallelism") -}}
{{- $apiParallelism := default 1 (index .Values "node-api-runtime" "parallelism") -}}
{{- printf "%d" (add $browserParallelism $apiParallelism) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "serverless-job-manager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "serverless-job-manager.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}