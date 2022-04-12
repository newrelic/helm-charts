{{- /*
Return the proper image name
{{ include "newrelic.common.images.image" ( dict "imageRoot" .Values.path.to.the.image "context" .) }}
*/ -}}
{{- define "newrelic.common.images.image" -}}
    {{- $registryName := include "newrelic.common.images.registry" ( dict "imageRoot" .imageRoot "context" .context) -}}
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
{{ include "newrelic.common.images.registry" ( dict "imageRoot" .Values.path.to.the.image "context" .) }}
*/ -}}
{{- define "newrelic.common.images.registry" -}}
    {{- if .imageRoot.registry -}}
        {{- .imageRoot.registry -}}
    {{- else if .context.Values.global -}}
        {{- if .context.Values.global.image -}}
            {{- with .context.Values.global.image.registry -}}
                {{- . -}}
            {{- end -}}
        {{- end -}}
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
{{ include "newrelic.common.images.renderPullSecrets" ( dict "pullSecrets" (list .Values.path.to.the.image.pullSecrets1, .Values.path.to.the.image.pullSecrets2) "context" .) }}
*/ -}}
{{- define "newrelic.common.images.renderPullSecrets" -}}
  {{- $flatlist := list }}

  {{- if .context.Values.global -}}
    {{- if .context.Values.global.image -}}
      {{- if .context.Values.global.image.pullSecrets -}}
        {{- range .context.Values.global.image.pullSecrets -}}
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
