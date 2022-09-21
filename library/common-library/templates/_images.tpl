{{- /*
Return the proper image name
{{ include "newrelic.common.images.image" ( dict "imageRoot" .Values.path.to.the.image "defaultRegistry" "your.private.registry.tld" "context" .) }}
*/ -}}
{{- define "newrelic.common.images.image" -}}
    {{- $registryName := include "newrelic.common.images.registry" ( dict "imageRoot" .imageRoot "defaultRegistry" .defaultRegistry "context" .context ) -}}
    {{- $repositoryName := include "newrelic.common.images.repository" .imageRoot -}}
    {{- $tag := include "newrelic.common.images.tag" ( dict "imageRoot" .imageRoot "context" .context) -}}

    {{- if $registryName -}}
        {{- printf "%s/%s:%s" $registryName $repositoryName $tag | quote -}}
    {{- else -}}
        {{- printf "%s:%s" $repositoryName $tag | quote -}}
    {{- end -}}
{{- end -}}



{{- /*
Return the proper image registry
{{ include "newrelic.common.images.registry" ( dict "imageRoot" .Values.path.to.the.image "defaultRegistry" "your.private.registry.tld" "context" .) }}
*/ -}}
{{- define "newrelic.common.images.registry" -}}
{{- $globalRegistry := "" -}}
{{- if .context.Values.global -}}
    {{- if .context.Values.global.images -}}
        {{- with .context.Values.global.images.registry -}}
            {{- $globalRegistry = . -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{- $localRegistry := "" -}}
{{- if .imageRoot.registry -}}
    {{- $localRegistry = .imageRoot.registry -}}
{{- end -}}

{{- $registry := $localRegistry | default $globalRegistry | default .defaultRegistry -}}
{{- if $registry -}}
    {{- $registry -}}
{{- end -}}
{{- end -}}



{{- /*
Return the proper image repository
{{ include "newrelic.common.images.repository" .Values.path.to.the.image }}
*/ -}}
{{- define "newrelic.common.images.repository" -}}
    {{- .repository -}}
{{- end -}}



{{- /*
Return the proper image tag
{{ include "newrelic.common.images.tag" ( dict "imageRoot" .Values.path.to.the.image "context" .) }}
*/ -}}
{{- define "newrelic.common.images.tag" -}}
    {{- .imageRoot.tag | default .context.Chart.AppVersion | toString -}}
{{- end -}}



{{- /*
Return the proper Image Pull Registry Secret Names evaluating values as templates
{{ include "newrelic.common.images.renderPullSecrets" ( dict "pullSecrets" (list .Values.path.to.the.images.pullSecrets1, .Values.path.to.the.images.pullSecrets2) "context" .) }}
*/ -}}
{{- define "newrelic.common.images.renderPullSecrets" -}}
  {{- $flatlist := list }}

  {{- if .context.Values.global -}}
    {{- if .context.Values.global.images -}}
      {{- if .context.Values.global.images.pullSecrets -}}
        {{- range .context.Values.global.images.pullSecrets -}}
          {{- $flatlist = append $flatlist . -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range .pullSecrets -}}
    {{- if not (empty .) -}}
      {{- range . -}}
        {{- $flatlist = append $flatlist . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if $flatlist -}}
    {{- toYaml $flatlist -}}
  {{- end -}}
{{- end -}}
