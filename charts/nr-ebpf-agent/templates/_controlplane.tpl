{{/*
Determine whether the cluster collector should scrape the control plane
(kube-apiserver / controller-manager / scheduler). Returns "true" or "" (falsy).

Why: scraping kube-apiserver /metrics is expensive — the endpoint returns ~26k
series (~3.6 MB) with no server-side filtering, and the collector keeps ~6. The
prometheus receiver buffers the whole body and caches every dropped series, costing
~22 MB of collector heap. On managed control planes (EKS/GKE/AKS) this mirrors what
nri-bundle does: its control-plane DaemonSet only schedules on control-plane nodes
(nodeAffinity on node-role.kubernetes.io/control-plane|controlplane|etcd), so on a
managed cluster it never scrapes the control plane at all.

Modes (.Values.nrdotCollector.controlPlane.mode, default "auto"):
  "always" -> always scrape
  "never"  -> never scrape
  "auto"   -> scrape only if the cluster has control-plane nodes (labelled
              node-role.kubernetes.io/control-plane|controlplane|master|etcd).
              Managed control planes expose no such node -> no scrape.
              `lookup` is inert during `helm template`/client-side --dry-run
              (returns no nodes); in that case we preserve current behaviour
              (scrape) so rendered output is unchanged. A real install/upgrade
              (or --dry-run=server) performs the lookup and detects correctly.
*/}}
{{- define "nr-ebpf-agent.controlPlane.shouldScrape" -}}
{{- $cp := .Values.nrdotCollector.controlPlane | default dict -}}
{{- $mode := $cp.mode | default "auto" -}}
{{- if eq $mode "always" -}}
true
{{- else if eq $mode "never" -}}
{{- else -}}
{{- $nodes := (lookup "v1" "Node" "" "") -}}
{{- if and $nodes $nodes.items -}}
  {{- /* real cluster: scrape only if a control-plane node exists */ -}}
  {{- $found := false -}}
  {{- range $nodes.items -}}
    {{- $labels := .metadata.labels | default dict -}}
    {{- if or (hasKey $labels "node-role.kubernetes.io/control-plane") (hasKey $labels "node-role.kubernetes.io/controlplane") (hasKey $labels "node-role.kubernetes.io/master") (hasKey $labels "node-role.kubernetes.io/etcd") -}}
      {{- $found = true -}}
    {{- end -}}
  {{- end -}}
  {{- if $found }}true{{- end -}}
{{- else -}}
  {{- /* lookup inert (helm template / client dry-run): preserve current behaviour */ -}}
true
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Processors shared by the control-plane pipelines (cluster Deployment: apiserver;
control-plane DaemonSet: controller-manager, scheduler, etcd). Render at column 0; callers nindent.
*/}}
{{- define "nr-ebpf-agent.controlPlane.processors" -}}
# Control-plane pipeline keeps service.name / service.instance.id, as canonical
# nr-k8s-otel-collector does (no resource/drop_scrape_meta there): the dashboard
# facets on service.instance.id. k8s.cluster.info still synthesizes the cluster via
# the service.name + newrelic.entity.type rule, and newrelic.entity.type=k8s keeps
# OTel EXT-SERVICE rules from matching. Both processors below are verbatim canonical.
{{- if include "nr-ebpf-agent.lowDataMode" . }}
resource/low_data_mode_inator:
  attributes:
    - key: http.scheme
      action: delete
    - key: net.host.name
      action: delete
    - key: net.host.port
      action: delete
    - key: url.scheme
      action: delete
    - key: server.address
      action: delete
{{- end }}
attributes/self:
  actions:
    - key: k8s.node.name
      action: upsert
      from_attribute: node
    - key: k8s.namespace.name
      action: upsert
      from_attribute: namespace
    - key: k8s.pod.name
      action: upsert
      from_attribute: pod
    - key: k8s.container.name
      action: upsert
      from_attribute: container
    - key: k8s.replicaset.name
      action: upsert
      from_attribute: replicaset
    - key: k8s.deployment.name
      action: upsert
      from_attribute: deployment
    - key: k8s.statefulset.name
      action: upsert
      from_attribute: statefulset
    - key: k8s.daemonset.name
      action: upsert
      from_attribute: daemonset
    - key: k8s.job.name
      action: upsert
      from_attribute: job_name
    - key: k8s.cronjob.name
      action: upsert
      from_attribute: cronjob
    - key: k8s.replicationcontroller.name
      action: upsert
      from_attribute: replicationcontroller
    - key: k8s.hpa.name
      action: upsert
      from_attribute: horizontalpodautoscaler
    - key: k8s.resourcequota.name
      action: upsert
      from_attribute: resourcequota
    - key: k8s.volume.name
      action: upsert
      from_attribute: volumename
    - key: k8s.volume.name
      action: upsert
      from_attribute: persistentvolume
    - key: k8s.pvc.name
      action: upsert
      from_attribute: persistentvolumeclaim
    - key: node
      action: delete
    - key: namespace
      action: delete
    - key: pod
      action: delete
    - key: container
      action: delete
    - key: replicaset
      action: delete
    - key: deployment
      action: delete
    - key: statefulset
      action: delete
    - key: daemonset
      action: delete
    - key: job_name
      action: delete
    - key: cronjob
      action: delete
    - key: replicationcontroller
      action: delete
    - key: horizontalpodautoscaler
      action: delete
    - key: resourcequota
      action: delete
    - key: volumename
      action: delete
    - key: persistentvolume
      action: delete
    - key: persistentvolumeclaim
      action: delete
{{- end -}}
