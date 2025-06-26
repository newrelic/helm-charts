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
{{- define "nrKubernetesOtel.metricsPipeline.collectorIngress.processors" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collectorIngress -}}
        {{- if .Values.metricsPipeline.collectorIngress.processors -}}
            {{- toYaml .Values.metricsPipeline.collectorIngress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the metrics preprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.metricsPipeline.collectorIngress.exporters" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collectorIngress -}}
        {{- if .Values.metricsPipeline.collectorIngress.exporters -}}
            {{- toYaml .Values.metricsPipeline.collectorIngress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what processors to include in the metrics postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.metricsPipeline.collectorEgress.processors" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collectorEgress -}}
        {{- if .Values.metricsPipeline.collectorEgress.processors -}}
            {{- toYaml .Values.metricsPipeline.collectorEgress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the metrics postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.metricsPipeline.collectorEgress.exporters" -}}
    {{- if .Values.metricsPipeline -}}
      {{- if .Values.metricsPipeline.collectorEgress -}}
        {{- if .Values.metricsPipeline.collectorEgress.exporters -}}
            {{- toYaml .Values.metricsPipeline.collectorEgress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what processors to include in the logs preprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collectorIngress.processors" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collectorIngress -}}
        {{- if .Values.logsPipeline.collectorIngress.processors -}}
            {{- toYaml .Values.logsPipeline.collectorIngress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the logs preprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collectorIngress.exporters" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collectorIngress -}}
        {{- if .Values.logsPipeline.collectorIngress.exporters -}}
            {{- toYaml .Values.logsPipeline.collectorIngress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what processors to include in the logs postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collectorEgress.processors" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collectorEgress -}}
        {{- if .Values.logsPipeline.collectorEgress.processors -}}
            {{- toYaml .Values.logsPipeline.collectorEgress.processors -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{- /* Defines what exporters to include in the logs postprocessor pipeline */ -}}
{{- define "nrKubernetesOtel.logsPipeline.collectorEgress.exporters" -}}
    {{- if .Values.logsPipeline -}}
      {{- if .Values.logsPipeline.collectorEgress -}}
        {{- if .Values.logsPipeline.collectorEgress.exporters -}}
            {{- toYaml .Values.logsPipeline.collectorEgress.exporters -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
{{- end -}}
