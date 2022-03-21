{{- /*
This file contains helpers to handle whether the chart should assume it is fine to deploy itself with elevated
privileges, thus changing the defaults for hostNetwork, securityContexts, etc.
Please note that either local or global definitions of the aforementioned settings will override the privileged flag.
*/ -}}

{{- /*
common.privileged is a helper that returns whether the chart should assume the user is fine deploying privileged pods.
Chart writers should _not_ use this to populate securityContext.privileged directly, but rather to tweak their implementation of:
- common.securityContext.containerDefaults
- common.securityContext.podDefaults
- common.hostNetwork.defaultOverride
And then use the helpers this library provides to render those.
*/ -}}
{{- /* Chart writers should not rely on this helper directly. */ -}}
{{- define "common.privileged" -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists. */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if get .Values "privileged" | kindIs "bool" -}}
{{- if .Values.privileged -}}
{{- .Values.privileged -}}
{{- end -}}
{{- else if get $global "privileged" | kindIs "bool" -}}
{{- if $global.privileged -}}
{{- $global.privileged -}}
{{- end -}}
{{- else -}}
{{- include "common.privileged.defaultOverride" . -}}
{{- end -}}
{{- end -}}


{{- /*
This allows to change the default user setting for `privileged`, by default it returns a falsy value ("").
*/ -}}
{{- define "common.privileged.defaultOverride" -}}
{{- end -}}
