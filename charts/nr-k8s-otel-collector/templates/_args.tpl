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
{{- /* Disable resource detection error propagation to restore v0.135.0 behavior where detection failures are logged but non-fatal */ -}}
{{- $defaultDaemonsetArgs := list "--config" "/config/daemonset-config.yaml" "--feature-gates" "metricsgeneration.MatchAttributes,-processor.resourcedetection.propagateerrors" }}
{{- if .Values.daemonset.extraArgs -}}
    {{- toYaml (concat $defaultDaemonsetArgs .Values.daemonset.extraArgs) }}
{{- else -}}
    {{- toYaml $defaultDaemonsetArgs -}}
{{- end -}}
{{- end -}}
