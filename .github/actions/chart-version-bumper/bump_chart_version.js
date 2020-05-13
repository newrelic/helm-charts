const yaml = require("yaml");
const { strOptions } = require('yaml/types');

// bumpChartVersion bumps the chartVersion and appVersion of the given chart.
exports.bumpChartVersion = function(chartYAML, chartVersion, appVersion) {
var doc;
try {
// allow unbounded line width, to prevent us changing the YAML document unnecessary 
strOptions.fold.lineWidth = 0
// indentSeq is set to false, which is similar to standard Helm Chart.yamls indentation 
doc = yaml.parseDocument(chartYAML, {indentSeq: false, })
} catch(error) {
throw Error(`Could not parse the given document as YAML: ${error}`)
}

const currentChartVersion = doc.get("version");
const currentAppVersion = doc.get("appVersion");

var changes = [] 
if (chartVersion != "" && currentChartVersion != chartVersion) {
doc.set("version", chartVersion);
changes.push({field: "chartVersion", from: currentChartVersion, to: chartVersion}); 
}

if (appVersion != "" && currentAppVersion != appVersion) {
doc.set("appVersion",  appVersion);
changes.push({field: "appVersion", from: currentAppVersion, to: appVersion});
}
   
return {newYAML: doc.toString(), changes};
};