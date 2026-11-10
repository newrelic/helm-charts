{{- /*
PCG applies changes to the watched ConfigMap (see watchedConfigMap) by reloading its
pipeline in place. Images older than the first release with this behaviour never pick
up a change, and nothing else in this chart restarts the pod for them. Fail rather than
render a deployment that silently ignores config updates.

Every semver tag is checked, pre-releases included: 3.3.0-rc.1 passes, 3.2.0-fedlogs
does not. Other tags (digests, branch builds) are the user's responsibility.
*/ -}}
{{- define "nrKubernetesOtel.hotReload.minImageVersion" -}}
3.3.0
{{- end -}}

{{- define "nrKubernetesOtel.hotReload.checkImage" -}}
{{- $watchedConfigMap := include "nrKubernetesOtel.hotReload.watchedConfigMap" . -}}
{{- $imageTag := toString (.Values.image.tag | default .Chart.AppVersion) | trimPrefix "v" -}}
{{- $minVersion := include "nrKubernetesOtel.hotReload.minImageVersion" . -}}
{{- if and (regexMatch "^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?(\\+[0-9A-Za-z.-]+)?$" $imageTag) (semverCompare (printf "<%s-0" $minVersion) $imageTag) -}}
{{- fail (printf "image.tag %q does not reload config changes in place, and this chart no longer restarts the pod when ConfigMap %q changes. Use image.tag %s or later, or an older chart version." $imageTag $watchedConfigMap $minVersion) -}}
{{- end -}}
{{- end -}}

{{- /*
The ConfigMap PCG reloads in place: the customConfigMap in fluxless mode, otherwise the
ConfigMap this chart renders (flux mode). A config change never restarts the pods.
*/ -}}
{{- define "nrKubernetesOtel.hotReload.watchedConfigMap" -}}
{{- if .Values.daemonset.enabled -}}
{{- .Values.daemonset.customConfigMap | default (include "nrKubernetesOtel.daemonset.configMap.fullname" .) -}}
{{- else -}}
{{- .Values.deployment.customConfigMap | default (include "nrKubernetesOtel.deployment.configMap.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- /*
"true" when PCG should follow the watched ConfigMap through the Kubernetes API rather than
the mounted file (configReload.source: kubernetes).
*/ -}}
{{- define "nrKubernetesOtel.hotReload.watchesAPI" -}}
{{- if eq (toString .Values.configReload.source) "kubernetes" -}}
true
{{- end -}}
{{- end -}}

{{- /*
Env vars that point PCG's config watcher at the watched ConfigMap through the Kubernetes API.
With source: file there are none: PCG watches the mounted file.
*/ -}}
{{- define "nrKubernetesOtel.hotReload.env" -}}
{{- if include "nrKubernetesOtel.hotReload.watchesAPI" . }}
- name: PCG_CONFIG_SOURCE
  value: kubernetes
- name: PCG_CONFIGMAP_NAME
  value: {{ include "nrKubernetesOtel.hotReload.watchedConfigMap" . | quote }}
{{- end }}
{{- end -}}
