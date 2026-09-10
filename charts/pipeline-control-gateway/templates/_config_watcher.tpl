{{- /*
A helper to render the config-watcher sidecar container.
Accepts a dict with:
  - customConfigMap: the ConfigMap name to watch
  - root: the root context (.)
*/ -}}
{{- define "nrKubernetesOtel.configWatcher.container" -}}
- name: config-watcher
  image: {{ .root.Values.configWatcher.image }}
  imagePullPolicy: {{ .root.Values.configWatcher.imagePullPolicy }}
  command:
    - /bin/bash
    - -c
    - |
      set -e

      CONFIGMAP_NAME="{{ .customConfigMap }}"
      NAMESPACE="{{ .root.Release.Namespace }}"
      POD_NAME="${MY_POD_NAME}"

      echo "Config watcher started. Monitoring ConfigMap: ${CONFIGMAP_NAME}"
      echo "Will restart pod: ${POD_NAME} in namespace: ${NAMESPACE} when a configuration update is detected"

      # Get initial resource version
      LAST_VERSION=$(kubectl get configmap "${CONFIGMAP_NAME}" -n "${NAMESPACE}" -o jsonpath='{.metadata.resourceVersion}')
      echo "Initial ConfigMap resourceVersion: ${LAST_VERSION}"

      # The Kubernetes API server terminates watch streams after its
      # --min-request-timeout (typically every 30-60 min).
      # Watch ConfigMap changes on a loop so it reconnects on those
      # natural terminations and transient errors.
      while true; do
        echo "Opening watch on ConfigMap ${CONFIGMAP_NAME}..."
        while read -r CURRENT_VERSION; do
          if [ -z "$CURRENT_VERSION" ]; then
            sleep 1
            continue
          fi

          echo "Event received. ResourceVersion: ${CURRENT_VERSION}"

          if [ "$CURRENT_VERSION" != "$LAST_VERSION" ]; then
            echo "ConfigMap change detected! ResourceVersion changed from ${LAST_VERSION} to ${CURRENT_VERSION}"
            echo "Deleting pod ${POD_NAME} to trigger restart..."

            kubectl delete pod "${POD_NAME}" -n "${NAMESPACE}" --grace-period={{ .root.Values.configWatcher.gracePeriod }}

            echo "Pod deletion initiated. Kubernetes will recreate the pod with new config."
            exit 0
          fi

          LAST_VERSION="${CURRENT_VERSION}"
        done < <(kubectl get configmap "${CONFIGMAP_NAME}" -n "${NAMESPACE}" --watch -o jsonpath='{.metadata.resourceVersion}{"\n"}' || true)

        echo "Watch stream ended (server timeout or transient error). Reconnecting in 2s..."
        sleep 2
      done
  env:
    - name: MY_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
  resources:
    {{- toYaml .root.Values.configWatcher.resources | nindent 4 }}
{{- end -}}
