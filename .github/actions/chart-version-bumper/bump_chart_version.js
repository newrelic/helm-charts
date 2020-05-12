const fs = require('fs');
const yaml = require("yaml");
const { strOptions } = require('yaml/types')

// loadChart loads and parses a Chart.yaml at the given path.
// The parsed document is returned.
function loadChart(chartPath) {
    if (!fs.existsSync(chartPath)){
        throw Error(`Chart.yaml not found at: ${chartPath}. Are you sure the chart exists?`)
    }

    var contents;
    try {
        contents = fs.readFileSync(chartPath, 'utf8')
    } catch(error) {
        throw Error(`Could not read Chart.yaml contents: ${error}`)
    }

    var yamlContents;
    try {
        // allow unbounded line width
        strOptions.fold.lineWidth = 0
        yamlContents = yaml.parseDocument(contents, {indentSeq: false, })
    } catch(error) {
        throw Error(`Could not parse ${chartPath} as YAML: ${error}`)
    }

    return yamlContents
}

exports.bumpChartVersion = function(chartPath, chartVersion, appVersion) {
    const chartYAML = loadChart(chartPath)

    const currentChartVersion = chartYAML.get("version");
    const currentAppVersion = chartYAML.get("appVersion");

    var changes = [] 
    if (chartVersion != "" && currentChartVersion != chartVersion) {
        chartYAML.set("version", chartVersion);
        changes.push({field: "chartVersion", from: currentChartVersion, to: chartVersion}); 
    }

    if (appVersion != "" && currentAppVersion != appVersion) {
        chartYAML.set("appVersion", appVersion);
        changes.push({field: "appVersion", from: currentAppVersion, to: appVersion});
    }
    
    fs.writeFileSync(chartPath, chartYAML.toString());

    return changes;
};