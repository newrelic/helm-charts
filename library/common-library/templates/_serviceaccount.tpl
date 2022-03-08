{{- /* Defines if the service account has to be created or not */ -}}
{{- define "common.serviceAccount.create" -}}
{{- $valueFound := false -}}
{{- if get .Values "serviceAccount" | kindIs "map" -}}
    {{- if (get .Values.serviceAccount "create" | kindIs "bool") -}}
        {{- $valueFound = true -}}
        {{- if .Values.serviceAccount.create -}}
            {{- /*
                We want only to return when this is true, returning `false` here will template "false" (string) when doing
                an `(include "newrelic-logging.serviceAccount" .)`, which is not an "empty string" so it is `true` if it is used
                as an evaluation somewhere else.
            */ -}}
            {{- .Values.serviceAccount.create -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if not $valueFound -}}
    {{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
    {{- $global := index .Values "global" | default dict -}}
    {{- if get $global "serviceAccount" | kindIs "map" -}}
        {{- if get $global.serviceAccount "create" | kindIs "bool" -}}
            {{- if $global.serviceAccount.create -}}
                {{- $global.serviceAccount.create -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}



{{- /* Defines the name of the service account */ -}}
{{- define "common.serviceAccount.name" -}}
{{- $localServiceAccount := "" -}}
{{- if get .Values "serviceAccount" | kindIs "map" -}}
    {{- if (get .Values.serviceAccount "name" | kindIs "string") -}}
        {{- $localServiceAccount = .Values.serviceAccount.name -}}
    {{- end -}}
{{- end -}}

{{- $globalServiceAccount := "" -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "serviceAccount" | kindIs "map" -}}
    {{- if get $global.serviceAccount "name" | kindIs "string" -}}
        {{- $globalServiceAccount = $global.serviceAccount.name -}}
    {{- end -}}
{{- end -}}

{{- if (include "common.serviceAccount.create" .) -}}
    {{- $globalServiceAccount | default $localServiceAccount | default (include "common.naming.fullname" .) -}}
{{- else -}}
    {{- $globalServiceAccount | default $localServiceAccount | default "default" -}}
{{- end -}}
{{- end -}}



{{- /* Merge the global and local annotations for the service account */ -}}
{{- define "common.serviceAccount.annotations" -}}
{{- $localServiceAccount := dict -}}
{{- if get .Values "serviceAccount" | kindIs "map" -}}
    {{- if get .Values.serviceAccount "annotations" -}}
        {{- $localServiceAccount = .Values.serviceAccount.annotations -}}
    {{- end -}}
{{- end -}}

{{- $globalServiceAccount := dict -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "serviceAccount" | kindIs "map" -}}
    {{- if get $global.serviceAccount "annotations" -}}
        {{- $globalServiceAccount = $global.serviceAccount.annotations -}}
    {{- end -}}
{{- end -}}

{{- $merged := mustMergeOverwrite $globalServiceAccount $localServiceAccount -}}

{{- if $merged -}}
    {{- toYaml $merged -}}
{{- end -}}
{{- end -}}
