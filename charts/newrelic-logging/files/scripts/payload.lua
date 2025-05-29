function build_payload(tag, timestamp, record)
    local payload = {{
        metrics = {{
            name = "fluentbit_build_info",
            type = "count",
            value = 0,
            timestamp = 1748536028,
            attributes = {
                app = "fluent-bit",
                arch = "amd642",
                prometheus_server = "ip-172-31-35-254",
                source = "kubernetes",
                version = "3.1.9",
                namespace = "newrelic",
                cluster_name = "preethi-212",
                daemonset_name = "newrelic-bundle-newrelic-logging-2"
            },
            ["interval.ms"] = 10000
        }}
    }}
    return 2, timestamp, payload
end