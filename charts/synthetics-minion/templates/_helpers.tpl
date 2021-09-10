{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "synthetics-minion.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allows to override the appVersion to use.
*/}}
{{- define "synthetics-minion.appVersion" -}}
{{- default .Chart.AppVersion .Values.appVersionOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "synthetics-minion.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "synthetics-minion.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Pod annotations
*/}}
{{- define "synthetics-minion.podAnnotations" -}}
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
Selector labels
*/}}
{{- define "synthetics-minion.selectorLabels" -}}
app.kubernetes.io/name: {{ include "synthetics-minion.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "synthetics-minion.labels" -}}
helm.sh/chart: {{ include "synthetics-minion.chart" . }}
{{ include "synthetics-minion.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "synthetics-minion.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "synthetics-minion.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
**************** Volume and Persistent Volume Claim Template name ****************

When we use PersistentVolumeClaimTemplate (i.e. claimName is undefined or empty) the name of the volume mounts defined
for the minion should be defined as the name of the PersistentVolumeClaimTemplate

When we DO NOT USE PersistentVolumeClaimTemplate (i.e. claimName is provided non-empty, i.e. the user wants to bind the
minion to an already existing PVC / PV statically provided), we create a volume and its name should be used to define
the name of the volume mounts for the minion.

The following synthetics-minion.volumeName and synthetics-minion.persistentVolumeClaimTemplateName and the way they're
used in the templates ensure all of the above
*/}}

{{/*
Create the name of the volume to associate to the minion pod
*/}}
{{- define "synthetics-minion.volumeName" -}}
minion-volume
{{- end -}}

{{/*
Create the name of the Persistent Volume Claim Template
*/}}
{{- define "synthetics-minion.persistentVolumeClaimTemplateName" -}}
{{ include "synthetics-minion.volumeName" . -}}
{{- end -}}

{{/*
**************** Volume and Persistent Volume Claim Template name /end ****************
*/}}

{{/*
Create the name of the Headless service to use for statefulsets
*/}}
{{- define "synthetics-minion.headlessServiceName" -}}
{{ default (include "synthetics-minion.fullname" .) .Values.headlessService.serviceName -}}
{{- end -}}

{{/*
Create the subpath for the /tmp directory for this minion
*/}}
{{- define "synthetics-minion.subPathTmp" -}}
{{- printf "%s/tmp" (include "synthetics-minion.fullname" .) -}}
{{- end -}}


{{/*
Default the replica to 1 if a persistent volume claim name is specified by the user, even if the replicacount is overridden
if the claim name is not provided then the replicacount override will be honoured.
This is logic is to ensure that we serve only 1 replica of Minion to address the accessMode: RWO.

If the replication count is more than one this could lead to :
- All the Minion replicas get scheduled on the as node which has access to PVC.
- Having multiple minion replicas work on the same folder could lead to race conditions reading/modifying the files in
  shared folders like customModules.

*/}}
{{- define "synthetics-minion.replica-count" -}}
{{- if and .Values.persistence.claimName (eq .Values.persistence.accessMode "ReadWriteOnce") -}}
{{- 1 -}}
{{- else -}}
{{- .Values.replicaCount -}}
{{- end -}}
{{- end -}}

{{/*
Calculates the terminationGracePeriodSeconds for the minion.
In order to prevent data-loss the grace period should be configured to be > synthetics job timeout, which is 240s by
default
*/}}
{{- define "synthetics-minion.terminationGracePeriodSeconds" -}}
{{- $checkTimeout := default 240 .Values.synthetics.minionCheckTimeout -}}
{{- printf "%d" (add $checkTimeout 20) -}}
{{- end -}}

{{/*
Calculates the maxProxyPortRange for the minion.
Depending on the number of heavy workers that are configured for the minion, we need to calculate the maximum number of ports
to expose in the statefulset.yaml
*/}}
{{- define "synthetics-minion.maxProxyPortRange" -}}
{{- $maxPorts := default 2 .Values.synthetics.heavyWorkers -}}
{{- printf "%d" (add 65101 (min $maxPorts 50)) -}}
{{- end -}}

{{/*
Define the static gid (3729) that needs to be used in the Minion podSecurityContext
This gid cannot be changed as it needs to match the one the runner will run as otherwise minion and runners won't be able to access shared artifacts on the file system (e.g. custom modules).
The id has no special meaning: it's arbitrarily picked from the [2000, 4999] range to avoid collision with other user accounts.
*/}}
{{- define "synthetics-minion.runAsGroup" -}}
{{- 3729 -}}
{{- end -}}

{{/*
Mount path for tmp directory
*/}}
{{- define "synthetics-minion.tmp-path" -}}
{{- "/tmp" -}}
{{- end -}}

{{/*
Mount path for permanent data storage directory
*/}}
{{- define "synthetics-minion.permanent-data-path" -}}
{{- "/var/lib/newrelic/synthetics" -}}
{{- end -}}

{{/*
Mount path for custom modules directory
*/}}
{{- define "synthetics-minion.custom-modules-path" -}}
{{- "/var/lib/newrelic/synthetics/modules" -}}
{{- end -}}

{{/*
Mount path for user defined variables directory
*/}}
{{- define "synthetics-minion.user-defined-variables-path" -}}
{{- "/var/lib/newrelic/synthetics/variables" -}}
{{- end -}}

{{/*
Define the volume mounts for the Minion
*/}}
{{- define "synthetics-minion.volumeMounts" }}
- mountPath: {{ include "synthetics-minion.tmp-path" . | quote }}
  name: {{ include "synthetics-minion.volumeName" . | quote }}
  subPath: {{ include "synthetics-minion.subPathTmp" . | quote}}
  {{ if .Values.persistence.permanentData }}
- mountPath: {{ include "synthetics-minion.permanent-data-path" . | quote }}
  name: {{ include "synthetics-minion.volumeName" . | quote }}
  subPath: {{ .Values.persistence.permanentData | quote }}
  {{ end }}
  {{ if .Values.persistence.customModules }}
- mountPath: {{ include "synthetics-minion.custom-modules-path" . | quote }}
  name: {{ include "synthetics-minion.volumeName" . | quote }}
  subPath: {{ .Values.persistence.customModules  | quote }}
  {{ end }}
  {{ if .Values.persistence.userDefinedVariables }}
- mountPath: {{ include "synthetics-minion.user-defined-variables-path" . | quote }}
  name: {{ include "synthetics-minion.volumeName" . | quote }}
  subPath: {{ .Values.persistence.userDefinedVariables | quote }}
  {{ end }}
{{- end }}

{{/*
Add privateLocationKey directly or retrieve from a Kubernetes Secret
*/}}
{{- define "synthetics-minion.privateLocationKey" }}
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
Add minionVsePassphrase directly or retrieve from a Kubernetes Secret
*/}}
{{- define "synthetics-minion.minionVsePassphrase" }}
{{- if or .Values.synthetics.minionVsePassphrase .Values.synthetics.minionVsePassphraseSecretName -}}
{{- if .Values.synthetics.minionVsePassphrase -}}
- name: MINION_VSE_PASSPHRASE
  value: {{ .Values.synthetics.minionVsePassphrase | quote }}
{{- else if .Values.synthetics.minionVsePassphraseSecretName -}}
- name: MINION_VSE_PASSPHRASE
  valueFrom:
secretKeyRef:
  name: {{ .Values.synthetics.minionVsePassphraseSecretName  }}
  key: minionVsePassphrase
{{- end -}}
{{- end -}}
{{- end }}
