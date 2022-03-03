{{/*
Return the proper image name
{{ include "common.images.image" ( dict "imageRoot" .Values.path.to.the.image "context" .) }}
*/}}
{{- define "common.images.image" -}}
{{- $registryName := "" -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $tag := .imageRoot.tag | default .context.Chart.AppVersion | toString -}}

{{- if .context.Values.global }}
    {{- if .context.Values.global.image.registry }}
     {{- $registryName = .context.Values.global.image.registry  -}}
    {{- end -}}
{{- end -}}

{{- with .imageRoot.registry }}
    {{- $registryName = . -}}
{{ end }}

{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag | quote -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag | quote -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names evaluating values as templates
{{ include "common.images.renderPullSecrets" ( dict "pullSecrets" (list .Values.path.to.the.image.pullSecrets1, .Values.path.to.the.image.pullSecrets2) "context" .) }}
*/}}
{{- define "common.images.renderPullSecrets" -}}
  {{- $ps := list }}

  {{- if .context.Values.global }}
    {{- if .context.Values.global.image }}
      {{- if .context.Values.global.image.pullSecrets }}
        {{- $ps = append $ps .context.Values.global.image.pullSecrets }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- range .pullSecrets -}}
    {{- if not (empty .) }}
      {{- $ps = append $ps . -}}
    {{- end -}}
  {{- end -}}

  {{- if gt (len $ps) 0 -}}
    {{- range $ps }}
{{ toYaml . }}
    {{- end -}}
  {{- end -}}
{{- end -}}