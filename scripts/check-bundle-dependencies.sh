#!/bin/bash

function failMessage() {
    echo -e "\033[0;31mTest with  values=\"$1\" and expected_charts=\"$1\" Failed\033[0m"
}

function checkDependencies()
{
    local values="$1"
    local expected_charts="$2"
    [[ "$values" == "" ]] && local values_set="global.cluster=test,global.licenseKey=fake" || local values_set="global.cluster=test,global.licenseKey=fake,$values"
    chart_sources=$(mktemp)
    helm template charts/nri-bundle --set $values_set | grep "# Source" > $chart_sources
    # Check no unexpected chart would be installed
    local expected_charts_re="${expected_charts// /|}" # replace ' ' with '|' "x y" -> "x|y"
    local unexpected_documents_count=$(cat $chart_sources | grep -v -E "$expected_charts_re" | wc -l | xargs)
    if [[ $unexpected_documents_count -gt 0 ]]
    then
        failMessage "${values}" "${expected_charts}"
        echo -e " The following charts are not expected to be installed with values \"$values_set\" but will be installed:"
        cat $chart_sources | grep -v -E "$expected_charts_re" | cut -d'/' -f3 | sort | uniq | xargs printf '\t\t* %s\n'
        return 1
    fi
    for chart in $expected_charts
    do
       local chart_documents_count=$(cat "$chart_sources" |grep "$chart" |wc -l |xargs)
       if [[ $chart_documents_count -eq 0 ]]
       then
            failMessage "${values}" "${expected_charts}"
            echo -e " The chart \"$chart\" is expected to be installed with values \"$values_set\" but it won't be installed."
            echo -e " The charts installed would be:"
            cat "$chart_sources" | cut -d'/' -f3 | sort | uniq | xargs printf '\t * %s\n'
            return 1
       fi
    done
    rm $chart_sources
}

ss=0

# Default values
values=""
expected_charts="newrelic-infrastructure nri-metadata-injection"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# nri-metadata-injection disabled
values="nri-metadata-injection.enabled=false"
expected_charts="newrelic-infrastructure"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# nri-metadata-injection disabled with legacy value
values="webhook.enabled=false"
expected_charts="newrelic-infrastructure"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# nri-prometheus enabled
values="nri-prometheus.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection nri-prometheus"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# nri-prometheus enabled with legacy value
values="prometheus.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection nri-prometheus"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# newrelic-prometheus-agent enabled
values="newrelic-prometheus-agent.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection newrelic-prometheus-agent"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# kube-state-metrics enabled
values="kube-state-metrics.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection kube-state-metrics"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# kube-state-metrics enabled with legacy value
values="ksm.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection kube-state-metrics"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# nri-kube-events enabled
values="nri-kube-events.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection nri-kube-events"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# nri-kube-events enabled with legacy value
values="kubeEvents.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection nri-kube-events"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# newrelic-logging enabled
values="newrelic-logging.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection newrelic-logging"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# newrelic-logging enabled with legacy value
values="logging.enabled=true"
expected_charts="newrelic-infrastructure nri-metadata-injection newrelic-logging"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))

# only newrelic-prometheus-agent enabled
values="newrelic-prometheus-agent.enabled=true,infrastructure.enabled=false,nri-metadata-injection.enabled=false"
expected_charts="newrelic-prometheus-agent"
checkDependencies  "${values}" "${expected_charts}" || ((ss++))


exit $ss
