{{- /*
A helper to return the args to pass into the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.args" -}}
{{- $defaultDeploymentArgs := list "--config" "/config/deployment-config.yaml" }}
{{- if .Values.deployment.extraArgs -}}
    {{- toYaml (concat $defaultDeploymentArgs .Values.deployment.extraArgs) }}
{{- else -}}
    {{- toYaml $defaultDeploymentArgs -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the args to pass into the daemonset.
*/ -}}
{{- define "nrKubernetesOtel.daemonset.args" -}}
{{- $defaultDaemonsetArgs := list "--config" "/config/daemonset-config.yaml" "--feature-gates" "metricsgeneration.MatchAttributes" }}
{{- if .Values.daemonset.extraArgs -}}
    {{- toYaml (concat $defaultDaemonsetArgs .Values.daemonset.extraArgs) }}
{{- else -}}
    {{- toYaml $defaultDaemonsetArgs -}}
{{- end -}}
{{- end -}}
