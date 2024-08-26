{{- define "newrelic-super-agent.capabilites-tester" -}}
{{- /* This variable is like this so renovate can in the future use regex to upgrade this (if possible) */ -}}
{{- /* Ref: https://github.com/fluxcd/flux2/blob/cc87ffd66e243fb85fc275792fa3708e44048048/cmd/flux/check.go#L62-L64 */ -}}
{{- /* The value above could change also if we have to create objects which API break (like Ingress on 1.24) or for testing purposes */ -}}
{{- $minimum_supported_version := ">=1.28.0-0" -}}
{{- $minimum_supported_version = (.Values.experimental).forceMinimumSupportedVersion | default $minimum_supported_version -}}

{{- $cluster_version := (.Values.experimental).forceKubeVersion | default .Capabilities.KubeVersion | toString -}}

{{- if not (semverCompare $minimum_supported_version $cluster_version) -}}
  {{- fail (printf "Kubernetes version is not supported. Cluster says its on version %s and does not meet %s" $cluster_version $minimum_supported_version ) -}}
{{- end -}}
{{- end -}}
