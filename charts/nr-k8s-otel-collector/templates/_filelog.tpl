{{- /*
  FILELOG RECEIVER CONFIGURATION

  This file contains the complete filelog collection flow:
  1. Receiver definition (filelog scraper configuration)
  2. Related processors (transforms, aggregations, filters)
  3. Pipeline routing instructions

  Organization:
1. RECEIVER - filelog scraper config
2. PROCESSORS - all filelog-specific transforms and filters
3. ROUTING - how filelog logs flow through pipelines

  Usage:
In daemonset.yaml receivers section:
  {{- include "nrKubernetesOtel.receivers.filelog.config" . | nindent 6 }}

In daemonset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.filelog.processors" . | nindent 6 }}

In daemonset.yaml connectors section:
  {{- include "nrKubernetesOtel.receivers.filelog.routing" . | nindent 6 }}
*/ -}}

{{- /* ========== RECEIVER DEFINITION ========== */ -}}

{{- /* filelog: Container logs from pod filesystem */ -}}
{{- define "nrKubernetesOtel.receivers.filelog.config" -}}
filelog:
  include:
    - /var/log/pods/*/*/*.log
  exclude:
    # Exclude logs from opentelemetry containers
    # filelog paths for containerd and CRI-O
{{- if include "newrelic.common.openShift" . }}
    - /var/log/pods/*/openshift*/*.log
{{- end -}}
    - /var/log/pods/*/otel-collector-daemonset/*.log
    - /var/log/pods/*/otel-collector-deployment/*.log
    - /var/log/pods/*/containers/*-exec.log
    # konnectivity-agent is GKE specific (gke uses containerd as default)
    - /var/log/pods/*/konnectivity-agent/*.log
    # filelog paths for docker CRI
    - /var/log/container/otel-collector-daemonset/*.log
    - /var/log/container/otel-collector-deployment/*.log
    - /var/log/containers/*-exec.log
  include_file_path: true
  include_file_name: true
  operators:
    - id: container-parser
      type: container
{{- end }}
