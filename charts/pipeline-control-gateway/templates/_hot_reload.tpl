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
{{- $customConfigMap := ternary .Values.daemonset.customConfigMap .Values.deployment.customConfigMap .Values.daemonset.enabled -}}
{{- $imageTag := toString (.Values.image.tag | default .Chart.AppVersion) | trimPrefix "v" -}}
{{- $minVersion := include "nrKubernetesOtel.hotReload.minImageVersion" . -}}
{{- if and $customConfigMap (regexMatch "^[0-9]+\\.[0-9]+\\.[0-9]+$" $imageTag) (semverCompare (printf "<%s" $minVersion) $imageTag) -}}
{{- fail (printf "image.tag %q does not reload config changes in place, and this chart no longer restarts the pod when customConfigMap %q changes. Use image.tag %s or later, or an older chart version." $imageTag $customConfigMap $minVersion) -}}
{{- end -}}
{{- end -}}
