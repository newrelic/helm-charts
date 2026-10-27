{{- /*
With a customConfigMap (fluxless mode), PCG applies ConfigMap changes by reloading
its pipeline in place. Images older than the first release with this behaviour
never pick up a change, and nothing else in this chart restarts the pod for them.
Fail rather than render a deployment that silently ignores config updates.

Only plain release tags (X.Y.Z) are checked; custom builds and pre-release tags
are the user's responsibility.
*/ -}}
{{- define "nrKubernetesOtel.hotReload.minImageVersion" -}}
2.6.0
{{- end -}}

{{- define "nrKubernetesOtel.hotReload.checkImage" -}}
{{- $customConfigMap := include "nrKubernetesOtel.hotReload.customConfigMap" . -}}
{{- $imageTag := toString (.Values.image.tag | default .Chart.AppVersion) | trimPrefix "v" -}}
{{- $minVersion := include "nrKubernetesOtel.hotReload.minImageVersion" . -}}
{{- if and $customConfigMap (regexMatch "^[0-9]+\\.[0-9]+\\.[0-9]+$" $imageTag) (semverCompare (printf "<%s" $minVersion) $imageTag) -}}
{{- fail (printf "image.tag %q does not reload config changes in place, and this chart no longer restarts the pod when customConfigMap %q changes. Use image.tag %s or later, or an older chart version." $imageTag $customConfigMap $minVersion) -}}
{{- end -}}
{{- end -}}

{{- /*
The fluxless ConfigMap, for whichever workload is enabled. Empty in flux mode.
*/ -}}
{{- define "nrKubernetesOtel.hotReload.customConfigMap" -}}
{{- ternary .Values.daemonset.customConfigMap .Values.deployment.customConfigMap .Values.daemonset.enabled -}}
{{- end -}}

{{- /*
"true" when PCG should follow the customConfigMap through the Kubernetes API rather than
the mounted file (configReload.source: kubernetes).
*/ -}}
{{- define "nrKubernetesOtel.hotReload.watchesAPI" -}}
{{- if and (include "nrKubernetesOtel.hotReload.customConfigMap" .) (eq (toString .Values.configReload.source) "kubernetes") -}}
true
{{- end -}}
{{- end -}}

{{- /*
Env vars that switch PCG's config watcher to the Kubernetes API. Images without that
support ignore them and keep watching the mounted file.
*/ -}}
{{- define "nrKubernetesOtel.hotReload.env" -}}
{{- if include "nrKubernetesOtel.hotReload.watchesAPI" . }}
- name: PCG_CONFIG_SOURCE
  value: kubernetes
- name: PCG_CONFIGMAP_NAME
  value: {{ include "nrKubernetesOtel.hotReload.customConfigMap" . | quote }}
{{- end }}
{{- end -}}
