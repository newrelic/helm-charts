{{- define "newrelic-super-agent.capabilites-tester" -}}
{{- $minimum_supported_version := (.Values.experimental).forceMinimumSupportedVersion | default .Chart.KubeVersion -}}

{{- $cluster_version := (.Values.experimental).forceKubeVersion | default .Capabilities.KubeVersion.Version | toString -}}

{{- if not (semverCompare $minimum_supported_version $cluster_version) -}}
  {{- $error_message := printf "Kubernetes version is not supported. Cluster says its on version %s and does not meet %s" $cluster_version $minimum_supported_version -}}
  {{- fail $error_message -}}
{{- end -}}
{{- end -}}
