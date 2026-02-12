{{- /*
A helper to return the pod security context to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.securityContext.pod" -}}
{{- if .Values.deployment.podSecurityContext -}}
    {{- toYaml .Values.deployment.podSecurityContext -}}
{{- else if include "newrelic.common.securityContext.pod" . -}}
    {{- include "newrelic.common.securityContext.pod" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the container security context to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.securityContext.container" -}}
{{- if .Values.deployment.containerSecurityContext -}}
    {{- toYaml .Values.deployment.containerSecurityContext -}}
{{- else if include "newrelic.common.securityContext.container" . -}}
    {{- include "newrelic.common.securityContext.container" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the pod security context to apply to the daemonset.
*/ -}}
{{- define "nrKubernetesOtel.daemonset.securityContext.pod" -}}
{{- if .Values.daemonset.podSecurityContext -}}
    {{- toYaml .Values.daemonset.podSecurityContext -}}
{{- else if include "newrelic.common.securityContext.pod" . -}}
    {{- include "newrelic.common.securityContext.pod" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the container security context to apply to the daemonset.
*/ -}}
{{- define "nrKubernetesOtel.daemonset.securityContext.container" -}}
{{- if .Values.daemonset.containerSecurityContext -}}
  {{if include "newrelic.common.gkeAutopilot" .}}
      {{- toYaml .Values.daemonset.containerSecurityContext | replace "privileged: true" "privileged: false" -}}
  {{else}}
      {{- toYaml .Values.daemonset.containerSecurityContext -}}
  {{end}}
{{- else if include "newrelic.common.securityContext.container" . -}}
  {{if .Values.gkeAutopilot}}
    {{- include "newrelic.common.securityContext.container" . | replace "privileged: true" "privileged: false" -}}
  {{else}}
    {{- include "newrelic.common.securityContext.container" . -}}
  {{end}}
{{- end -}}
{{- end -}}

{{- /*
A helper to determine if the daemonset should exclude the container storage overlay mount point.
This exclusion is only relevant for the CRI-O container runtime (used by OKE, OpenShift, etc.)
where non-root users cannot access /var/lib/containers/storage/overlay due to permission restrictions.
Returns "true" if running as non-root and non-privileged (needs exclusion to avoid permission errors).
Returns empty string if running as root or privileged (can access the mount point).
Respects precedence: daemonset.containerSecurityContext > containerSecurityContext > global.containerSecurityContext
*/ -}}
{{- define "nrKubernetesOtel.daemonset.excludeContainerStorageOverlay" -}}
{{- $securityContext := dict -}}
{{- if .Values.daemonset.containerSecurityContext -}}
  {{- $securityContext = .Values.daemonset.containerSecurityContext -}}
{{- else if .Values.containerSecurityContext -}}
  {{- $securityContext = .Values.containerSecurityContext -}}
{{- else if .Values.global.containerSecurityContext -}}
  {{- $securityContext = .Values.global.containerSecurityContext -}}
{{- end -}}
{{- $runAsRoot := and (hasKey $securityContext "runAsUser") (eq ($securityContext.runAsUser | int) 0) -}}
{{- $isPrivileged := $securityContext.privileged -}}
{{- if not (or $runAsRoot $isPrivileged) -}}
true
{{- end -}}
{{- end -}}
