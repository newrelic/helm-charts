# New Relic Logs: Kubernetes manifests
This directory provides plain Kubernetes manifests that can be applied to your cluster to install the Kubernetes Logging plugin. It is provided as an alternative for those users who prefer not using Helm.

## Installation instructions
* Create a `newrelic` namespace.  Run `kubectl create namespace newrelic`.
* Copy all the manifest files in this folder (*.yml files) in your local working directory.
* Configure the plugin. In new-relic-fluent-plugin.yml:
  * Specify your New Relic license key in the value for LICENSE_KEY
  * Specify your Kubernetes cluster name in the value for CLUSTER_NAME
  * If you are in the EU:
    * Override the ENDPOINT environment variable to https://log-api.eu.newrelic.com/log/v1
    * Make sure that the license key you are using is an EU key
* From your working directory, run `kubectl apply -f .` on your cluster
* Check [New Relic for your logs](https://docs.newrelic.com/docs/logs/new-relic-logs/get-started/introduction-new-relic-logs#find-data)

## Find and use your data

For how to find and query your data in New Relic, see [Find log data](https://docs.newrelic.com/docs/logs/new-relic-logs/get-started/introduction-new-relic-logs#find-data).

For general querying information, see:
- [Query New Relic data](https://docs.newrelic.com/docs/using-new-relic/data/understand-data/query-new-relic-data)
- [Intro to NRQL](https://docs.newrelic.com/docs/query-data/nrql-new-relic-query-language/getting-started/introduction-nrql)

## Configuration notes

We default to tailing `/var/log/containers/*.log`. If you want to change what's tailed, just update the `PATH` 
value in `new-relic-fluent-plugin.yml`.

By default, and to ensure backwards compatibility, we assume that `kubelet` communicates with the `Docker` container engine. With the introduction of the [CRI](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes/), logs placed under `/var/log/containers/*.log` follow a different format, even if they are originally produced in JSON format by the container. If you are using CRI, to be able to parse these logs correctly, you must set `LOG_PARSER` to `"cri"` in `new-relic-fluent-plugin.yml`.

## Parsing

We currently support parsing Docker (JSON) and [CRI](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes/) logs. If you want more parsing, feel free to add more parsers in `fluent-conf.yml`.

Here are some parsers for your parsing pleasure. 

```
[PARSER]
    Name   apache
    Format regex
    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z

[PARSER]
    Name   apache2
    Format regex
    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^ ]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z

[PARSER]
    Name   apache_error
    Format regex
    Regex  ^\[[^ ]* (?<time>[^\]]*)\] \[(?<level>[^\]]*)\](?: \[pid (?<pid>[^\]]*)\])?( \[client (?<client>[^\]]*)\])? (?<message>.*)$

[PARSER]
    Name   nginx
    Format regex
    Regex ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z
  ```   