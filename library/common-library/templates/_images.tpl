{{/*
Return the proper image name
{{ include "common.images.image" ( dict "imageRoot" .Values.path.to.the.image "context" .) }}
*/}}
{{- define "common.images.image" -}}
    {{- $registryName := include "common.images.registry" ( dict "imageRoot" .imageRoot "context" .context) -}}
    {{- $repositoryName := include "common.images.repository" .imageRoot -}}
    {{- $tag := include "common.images.tag" ( dict "imageRoot" .imageRoot "context" .context) -}}

    {{- if $registryName }}
        {{- printf "%s/%s:%s" $registryName $repositoryName $tag | quote -}}
    {{- else -}}
        {{- printf "%s:%s" $repositoryName $tag | quote -}}
    {{- end -}}
{{- end -}}

Return the proper image registry
{{ include "common.images.registry" ( dict "imageRoot" .Values.path.to.the.image "context" .) }}
*/}}
{{- define "common.images.registry" -}}
    {{- if .imageRoot.registry }}
        {{- .imageRoot.registry -}}
    {{- else if .context.Values.global }}
        {{- if .context.Values.global.image }}
            {{- with .context.Values.global.image.registry }}
                {{- .  -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

Return the proper image repository
{{ include "common.images.repository" .Values.path.to.the.image }}
*/}}
{{- define "common.images.repository" -}}
    {{- .repository -}}
{{- end -}}

Return the proper image tag
{{ include "common.images.tag" ( dict "imageRoot" .Values.path.to.the.image "context" .) }}
*/}}
{{- define "common.images.tag" -}}
    {{- .imageRoot.tag | default .context.Chart.AppVersion | toString -}}
{{- end -}}

{{/*
Return the proper Image Pull Registry Secret Names evaluating values as templates
{{ include "common.images.renderPullSecrets" ( dict "pullSecrets" (list .Values.path.to.the.image.pullSecrets1, .Values.path.to.the.image.pullSecrets2) "context" .) }}
*/}}
{{- define "common.images.renderPullSecrets" -}}
  {{- $ps := list -}}

  {{- if .context.Values.global -}}
    {{- if .context.Values.global.image -}}
      {{- if .context.Values.global.image.pullSecrets -}}
        {{- $ps = append $ps .context.Values.global.image.pullSecrets -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range .pullSecrets -}}
    {{- if not (empty .) -}}
      {{- $ps = append $ps . -}}
    {{- end -}}
  {{- end -}}

  {{- if gt (len $ps) 0 -}}
    {{- range $ps }}
{{ toYaml . }}
    {{- end -}}
  {{- end -}}
{{- end -}}
