{{- /* Defines if the deployment config map has to be created or not */ -}}
{{- define "nrKubernetesOtel.deployment.configMap.overrideConfig" -}}

{{- /* Look for a local creation of a deployment config map */ -}}
{{- if get .Values.deployment "configMap" | kindIs "map" -}}
    {{- if .Values.deployment.configMap.overrideConfig -}}
        {{- toYaml .Values.deployment.configMap.overrideConfig -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the deployment receivers have to be added to the config */ -}}
{{- define "nrKubernetesOtel.deployment.configMap.extraConfig.receivers" -}}

{{- if get .Values.deployment "configMap" | kindIs "map" -}}
    {{- if .Values.deployment.configMap.extraConfig -}}
        {{- if .Values.deployment.configMap.extraConfig.receivers -}}
            {{- toYaml .Values.deployment.configMap.extraConfig.receivers -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the deployment processors have to be added to the config */ -}}
{{- define "nrKubernetesOtel.deployment.configMap.extraConfig.processors" -}}

{{- if get .Values.deployment "configMap" | kindIs "map" -}}
    {{- if .Values.deployment.configMap.extraConfig -}}
        {{- if .Values.deployment.configMap.extraConfig.processors -}}
            {{- toYaml .Values.deployment.configMap.extraConfig.processors -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the deployment exporters have to be added to the config */ -}}
{{- define "nrKubernetesOtel.deployment.configMap.extraConfig.exporters" -}}

{{- if get .Values.deployment "configMap" | kindIs "map" -}}
    {{- if .Values.deployment.configMap.extraConfig -}}
        {{- if .Values.deployment.configMap.extraConfig.exporters -}}
            {{- toYaml .Values.deployment.configMap.extraConfig.exporters -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the deployment connectors have to be added to the config */ -}}
{{- define "nrKubernetesOtel.deployment.configMap.extraConfig.connectors" -}}

{{- if get .Values.deployment "configMap" | kindIs "map" -}}
    {{- if .Values.deployment.configMap.extraConfig -}}
        {{- if .Values.deployment.configMap.extraConfig.connectors -}}
            {{- toYaml .Values.deployment.configMap.extraConfig.connectors -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the deployment pipelines have to be added to the config */ -}}
{{- define "nrKubernetesOtel.deployment.configMap.extraConfig.pipelines" -}}

{{- if get .Values.deployment "configMap" | kindIs "map" -}}
    {{- if .Values.deployment.configMap.extraConfig -}}
        {{- if .Values.deployment.configMap.extraConfig.pipelines -}}
            {{- toYaml .Values.deployment.configMap.extraConfig.pipelines -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}


{{- /* Defines if the daemonset config map has to be created or not */ -}}
{{- define "nrKubernetesOtel.daemonset.configMap.overrideConfig" -}}

{{- /* Look for a local creation of a daemonset config map */ -}}
{{- if get .Values.daemonset "configMap" | kindIs "map" -}}
    {{- if .Values.daemonset.configMap.overrideConfig -}}
        {{- toYaml .Values.daemonset.configMap.overrideConfig -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the daemonset receivers have to be added to the config */ -}}
{{- define "nrKubernetesOtel.daemonset.configMap.extraConfig.receivers" -}}

{{- if get .Values.daemonset "configMap" | kindIs "map" -}}
    {{- if .Values.daemonset.configMap.extraConfig -}}
        {{- if .Values.daemonset.configMap.extraConfig.receivers -}}
            {{- toYaml .Values.daemonset.configMap.extraConfig.receivers -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the daemonset processors have to be added to the config */ -}}
{{- define "nrKubernetesOtel.daemonset.configMap.extraConfig.processors" -}}

{{- if get .Values.daemonset "configMap" | kindIs "map" -}}
    {{- if .Values.daemonset.configMap.extraConfig -}}
        {{- if .Values.daemonset.configMap.extraConfig.processors -}}
            {{- toYaml .Values.daemonset.configMap.extraConfig.processors -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the daemonset exporters have to be added to the config */ -}}
{{- define "nrKubernetesOtel.daemonset.configMap.extraConfig.exporters" -}}

{{- if get .Values.daemonset "configMap" | kindIs "map" -}}
    {{- if .Values.daemonset.configMap.extraConfig -}}
        {{- if .Values.daemonset.configMap.extraConfig.exporters -}}
            {{- toYaml .Values.daemonset.configMap.extraConfig.exporters -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the daemonset connectors have to be added to the config */ -}}
{{- define "nrKubernetesOtel.daemonset.configMap.extraConfig.connectors" -}}

{{- if get .Values.daemonset "configMap" | kindIs "map" -}}
    {{- if .Values.daemonset.configMap.extraConfig -}}
        {{- if .Values.daemonset.configMap.extraConfig.connectors -}}
            {{- toYaml .Values.daemonset.configMap.extraConfig.connectors -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if the daemonset pipelines have to be added to the config */ -}}
{{- define "nrKubernetesOtel.daemonset.configMap.extraConfig.pipelines" -}}

{{- if get .Values.daemonset "configMap" | kindIs "map" -}}
    {{- if .Values.daemonset.configMap.extraConfig -}}
        {{- if .Values.daemonset.configMap.extraConfig.pipelines -}}
            {{- toYaml .Values.daemonset.configMap.extraConfig.pipelines -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /* Defines if custom otel processors will be added to the config */ -}}
{{- define "nrKubernetesOtel.custom.processors" -}}
    {{- if .Values.processors -}}
            {{- toYaml .Values.processors -}}
    {{- end -}}
{{- end -}}

{{- /* Defines if custom otel exporters will be added to the config */ -}}
{{- define "nrKubernetesOtel.custom.exporters" -}}
    {{- if .Values.exporters -}}
            {{- toYaml .Values.exporters -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what processors to include in the metrics preprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.metricsPipeline.collector_ingress.processors" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collector_ingress -}}
        {{- if .Values.metricsPipeline.collector_ingress.processors -}}
            {{- toYaml .Values.metricsPipeline.collector_ingress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the metrics preprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.metricsPipeline.collector_ingress.exporters" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collector_ingress -}}
        {{- if .Values.metricsPipeline.collector_ingress.exporters -}}
            {{- toYaml .Values.metricsPipeline.collector_ingress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what processors to include in the metrics postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.metricsPipeline.collector_egress.processors" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collector_egress -}}
        {{- if .Values.metricsPipeline.collector_egress.processors -}}
            {{- toYaml .Values.metricsPipeline.collector_egress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the metrics postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.metricsPipeline.collector_egress.exporters" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collector_egress -}}
        {{- if .Values.metricsPipeline.collector_egress.exporters -}}
            {{- toYaml .Values.metricsPipeline.collector_egress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what processors to include in the logs preprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collector_ingress.processors" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collector_ingress -}}
        {{- if .Values.logsPipeline.collector_ingress.processors -}}
            {{- toYaml .Values.logsPipeline.collector_ingress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the logs preprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collector_ingress.exporters" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collector_ingress -}}
        {{- if .Values.logsPipeline.collector_ingress.exporters -}}
            {{- toYaml .Values.logsPipeline.collector_ingress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what processors to include in the logs postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collector_egress.processors" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collector_egress -}}
        {{- if .Values.logsPipeline.collector_egress.processors -}}
            {{- toYaml .Values.logsPipeline.collector_egress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the logs postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collector_egress.exporters" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collector_egress -}}
        {{- if .Values.logsPipeline.collector_egress.exporters -}}
            {{- toYaml .Values.logsPipeline.collector_egress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}
