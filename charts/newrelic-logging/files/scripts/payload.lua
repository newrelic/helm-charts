function build_payload(tag, timestamp, record)
    local payload = {{
        metrics = {{
            name = "fluentbit_build_info",
            type = "count",
            value = 0,
            timestamp = os.time(),
            attributes = {
                app = "fluent-bit",
                source = "kubernetes",
                version = record["fluentBitVersion"],
                namespace = os.getenv("NAMESPACE"),
                cluster_name = os.getenv("CLUSTER_NAME"),
                daemonset_name = os.getenv("DAEMONSET_NAME"),
                tier= os.getenv("FLUENTBIT_METRICS_TIER")            },
            ["interval.ms"] = 10000
        }}
    }}
    return 2, timestamp, payload
end