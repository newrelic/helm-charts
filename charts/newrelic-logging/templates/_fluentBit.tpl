{{/*This file is used for resolving fluent bit options*/}}

{{- define "newrelic.fluentBit.linuxMountPath" -}}
{{- if .Values.fluentBit.linuxMountPath -}}
{{- .Values.fluentBit.linuxMountPath -}}
{{- else if include "newrelic.common.gkeAutopilot" . -}}
/var/log
{{- else -}}
/var
{{- end -}}
{{- end -}}


{{- define "newrelic.fluentBit.persistence.mode" -}}
{{- if .Values.fluentBit.persistence.mode -}}
{{- .Values.fluentBit.persistence.mode -}}
{{- else if include "newrelic.common.gkeAutopilot" . -}}
none
{{- else -}}
hostPath
{{- end -}}
{{- end -}}
