{{/*Warning notes*/}}
{{ define "newrelic.common.notes.region" }}
{{ if and (include "newrelic.common.license._usesCustomSecret" .) (not (include "newrelic.common.region._fromValues" .)) }}
Warning: This chart was installed using a custom secret for the license key, but no region was specified. 
         You may need to set the `region` or `global.region` explicitly if your license key is for the EU or Japan regions.
         An explicitly configured `region` or `global.region` will be required in a future release.
{{ end }}
{{ end }}

{{ define "newrelic.common.notes.warning" }}
{{ include "newrelic.common.notes.region" . }}
{{ end }}


{{/*INFO notes*/}}
{{/*TODO:... */}}


{{ define "newrelic.common.notes" }}
{{ include "newrelic.common.notes.warning" . }}
{{/*TODO: Add Notes for Info */}}
{{ end }}