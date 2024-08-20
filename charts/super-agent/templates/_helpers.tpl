{{- define "newrelic-super-agent.capabilites-tester" -}}
{{- /* This variable is like this so renovate can in the future use regex to upgrade this (if possible) */ -}}
{{- /* Ref: https://github.com/fluxcd/flux2/blob/cc87ffd66e243fb85fc275792fa3708e44048048/cmd/flux/check.go#L62-L64 */ -}}
{{- /* The value above could change also if we have to create objects which API break (like Ingress on 1.24) */ -}}
{{- $minimumSupportedVersion := "1.28" -}}
{{- $minimumSupportedVersion = $minimumSupportedVersion | split "." -}}

{{- $from_cluster_major := ((.Capabilities).KubeVersion).Major | int -}}
{{- $supported_major := $minimumSupportedVersion._0 | int -}}
{{- if not (eq $from_cluster_major $supported_major) -}}
  {{- fail (printf "Breaking change in Kubernetes. We only support versions %s.xx" $supported_major) -}}
{{- end -}}

{{- $from_cluster_minor := ((.Capabilities).KubeVersion).Minor | int -}}
{{- $supported_minor := $minimumSupportedVersion._1 | int -}}
{{- if gt $supported_minor $from_cluster_minor -}}
  {{- fail (printf "Kuberentes version is not supported. Condition not met: %d.%d >= %d.%d" $from_cluster_major $from_cluster_minor $supported_major $supported_minor) -}}
{{- end -}}
{{- end -}}
