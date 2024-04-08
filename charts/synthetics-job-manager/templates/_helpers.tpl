{{/*
Expand the name of the chart.
*/}}
{{- define "synthetics-job-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "synthetics-job-manager.fullname" -}}
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
{{- define "synthetics-job-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allows to override the appVersion to use.
*/}}
{{- define "synthetics-job-manager.appVersion" -}}
{{- default .Chart.AppVersion .Values.appVersionOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allows overriding of the synthetics-job-manager Service hostname
*/}}
{{- define "synthetics-job-manager.hostname" -}}
{{- default "synthetics-job-manager" .Values.global.hostnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allows overriding of the ping-runtime Service hostname
*/}}
{{- define "ping-runtime.hostname" -}}
{{- default "ping" (index .Values "global" "ping-runtime" "hostnameOverride") | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Add internalApiKey directly or retrieve from a Kubernetes Secret
*/}}
{{- define "synthetics-job-manager.internalApiKey" }}
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
{{- define "synthetics-job-manager.apiProxyHost" }}
{{- if .Values.synthetics.apiProxyHost -}}
{{- if .Values.synthetics.apiProxyPort -}}
- name: HORDE_API_PROXY_HOST
  value: {{ .Values.synthetics.apiProxyHost | quote }}
{{- else -}}
{{- required ".Values.synthetics.apiProxyPort must be set if .Values.synthetics.apiProxyHost is set!" nil }}
{{- end -}}
{{- end }}
{{- end }}

{{/*
Ensures that proxy host is set if proxy port is set.
*/}}
{{- define "synthetics-job-manager.apiProxyPort" }}
{{- if .Values.synthetics.apiProxyPort -}}
{{- if .Values.synthetics.apiProxyHost -}}
- name: HORDE_API_PROXY_PORT
  value: {{ .Values.synthetics.apiProxyPort | quote }}
{{- else -}}
{{- required ".Values.synthetics.apiProxyHost must be set if .Values.synthetics.apiProxyPort is set!" nil }}
{{- end -}}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "synthetics-job-manager.labels" -}}
helm.sh/chart: {{ include "synthetics-job-manager.chart" . }}
{{ include "synthetics-job-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "synthetics-job-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "synthetics-job-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod annotations
*/}}
{{- define "synthetics-job-manager.podAnnotations" -}}
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
Add privateLocationKey directly or retrieve from a Kubernetes Secret
*/}}
{{- define "synthetics-job-manager.privateLocationKey" }}
{{- if .Values.synthetics.privateLocationKey -}}
value: {{ .Values.synthetics.privateLocationKey | quote }}
{{- else if .Values.synthetics.privateLocationKeySecretName -}}
valueFrom:
  secretKeyRef:
    name: {{ .Values.synthetics.privateLocationKeySecretName  }}
    key: privateLocationKey
{{- else -}}
{{- required ".Values.synthetics.privateLocationKey or .Values.synthetics.privateLocationKeySecretName must be set!" nil }}
{{- end -}}
{{- end }}

{{/*
Add vsePassphrase directly or retrieve from a Kubernetes Secret
*/}}
{{- define "synthetics-job-manager.vsePassphrase" }}
{{- if or .Values.synthetics.vsePassphrase .Values.synthetics.vsePassphraseSecretName -}}
{{- if .Values.synthetics.vsePassphrase -}}
- name: VSE_PASSPHRASE
  value: {{ .Values.synthetics.vsePassphrase | quote }}
{{- else if .Values.synthetics.vsePassphraseSecretName -}}
- name: VSE_PASSPHRASE
  valueFrom:
    secretKeyRef:
      name: {{ .Values.synthetics.vsePassphraseSecretName  }}
      key: vsePassphrase
{{- end -}}
{{- end -}}
{{- end }}


{{/*
Create the name of the volume to associate to the SJM pod
*/}}
{{- define "synthetics-job-manager.volumeName" -}}
sjm-volume
{{- end -}}

{{/*
Create the name of the PersistentVolumeClaim to use if Helm is generating one
*/}}
{{- define "synthetics-job-manager.defaultClaimName" -}}
sjm-pvc
{{- end -}}

{{/*
Use either the provided PersistentVolumeClaim name or the default PVC name
*/}}
{{- define "synthetics-job-manager.claimName" -}}
  {{ if (.Values.global.persistence).existingClaimName }}
  {{- (.Values.global.persistence).existingClaimName -}}
  {{ else }}
  {{- include "synthetics-job-manager.defaultClaimName" . -}}
  {{ end }}
{{- end -}}

{{/*
Config map name to be used when user provides user-defined variable file contents
*/}}
{{- define "synthetics-job-manager.configMapName" -}}
sjm-config
{{- end -}}

{{/*
Mount path for user defined variables directory
*/}}
{{- define "synthetics-job-manager.userDefinedVariablesPath" -}}
{{ "/var/lib/newrelic/synthetics/variables/" }}
{{- end -}}

{{/*
Mount path for custom node modules directory
*/}}
{{- define "synthetics-job-manager.customNodeModulesPath" -}}
{{ "/var/lib/newrelic/synthetics/modules/" }}
{{- end -}}

{{/*
yaml for User Defined Variables volume mount
*/}}
{{- define "synthetics-job-manager.userDefinedVarMount" -}}
- mountPath: {{ include "synthetics-job-manager.userDefinedVariablesPath" . | quote }}
  {{- if (.Values.synthetics.userDefinedVariables).userDefinedFile }}
  name: {{ include "synthetics-job-manager.configMapName" . | quote -}}
  {{ else }}
  name: {{ include "synthetics-job-manager.volumeName" . | quote }}
  {{ end }}
  {{ if (.Values.synthetics.userDefinedVariables).userDefinedPath }}
  subPath: {{ .Values.synthetics.userDefinedVariables.userDefinedPath | quote }}
  {{ end }}
{{- end -}}

{{/*
yaml for Custom Node Modules volume mount
*/}}
{{- define "synthetics-job-manager.customNodeModulesMount" -}}
- mountPath: {{ include "synthetics-job-manager.customNodeModulesPath" . | quote }}
  name: {{ include "synthetics-job-manager.volumeName" . | quote }}
  subPath: {{ .Values.global.customNodeModules.customNodeModulesPath  | quote }}
{{- end -}}

{{/*
Define the optional volume mounts for the SJM
*/}}
{{- define "synthetics-job-manager.volumeMounts" -}}
{{- if or (.Values.synthetics.userDefinedVariables).userDefinedPath (.Values.synthetics.userDefinedVariables).userDefinedFile -}}
{{ include "synthetics-job-manager.userDefinedVarMount" . }}
{{- end -}}
{{ if (.Values.global.customNodeModules).customNodeModulesPath }}
{{ include "synthetics-job-manager.customNodeModulesMount" . }}
{{- end -}}
{{- end -}}

{{/*
Define whether to mount volumes for the SJM
*/}}
{{- define "synthetics-job-manager.toMount" -}}
  {{ if or (include "synthetics-job-manager.toMountUserDefinedVars" .) (include "synthetics-job-manager.toMountCustomNodeModules" .) }}
  {{ end }}
{{- end -}}

{{/*
Define whether to mount custom node modules volume
*/}}
{{- define "synthetics-job-manager.toMountCustomNodeModules" -}}
  {{ if (.Values.global.customNodeModules).customNodeModulesPath }}
  {{ end }}
{{- end -}}

{{/*
Define whether to mount user-defined vars volume
*/}}
{{- define "synthetics-job-manager.toMountUserDefinedVars" -}}
  {{ if or (.Values.synthetics.userDefinedVariables).userDefinedPath (.Values.synthetics.userDefinedVariables).userDefinedFile }}
  {{ end }}
{{- end -}}

{{/*
Define whether to generate a PVC for the SJM. Checks whether the user has already provided an existing PVC name and if not,
whether they've provided an existing PV name.
*/}}
{{- define "synthetics-job-manager.generatePVC" -}}
  {{ if and (not (.Values.global.persistence).existingClaimName) (.Values.global.persistence).existingVolumeName }}
  {{ end }}
{{- end -}}

{{/*
Calculates the terminationGracePeriodSeconds.
In order to prevent data-loss the grace period should be configured to be > synthetics job timeout, which is 240s by
default
*/}}
{{- define "synthetics-job-manager.terminationGracePeriodSeconds" -}}
{{- $checkTimeout := default 240 .Values.global.checkTimeout -}}
{{- printf "%d" (add $checkTimeout 20) -}}
{{- end -}}

{{/*
Calculates the sum of parallelism of the ephemeral runtimes to configure the SJM parking lot
*/}}
{{- define "synthetics-job-manager.runtimeParallelism" -}}
{{- $browserParallelism := default 1 (index .Values "node-browser-runtime" "parallelism") -}}
{{- $apiParallelism := default 1 (index .Values "node-api-runtime" "parallelism") -}}
{{- printf "%d" (add $browserParallelism $apiParallelism) -}}
{{- end -}}
