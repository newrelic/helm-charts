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
Calculates the terminationGracePeriodSeconds.
In order to prevent data-loss the grace period should be configured to be > synthetics job timeout, which is 240s by
default
*/}}
{{- define "synthetics-job-manager.terminationGracePeriodSeconds" -}}
{{- $checkTimeout := default 240 .Values.synthetics.checkTimeout -}}
{{- printf "%d" (add $checkTimeout 20) -}}
{{- end -}}
