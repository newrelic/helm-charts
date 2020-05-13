const { bumpChartVersion } = require("./bump_chart_version");

function createChart (chartVersion, appVersion) {
    return `apiVersion: v1
name: redis
version: ${chartVersion}
appVersion: ${appVersion}
# The redis chart is deprecated and no longer maintained. For details deprecation, see the PROCESSES.md file.
deprecated: true
description: DEPRECATED Open source, advanced key-value store. It is often referred to as a data structure server since keys can contain strings, hashes, lists, sets and sorted sets.
keywords:
- redis
- keyvalue
- database
home: http://redis.io/
icon: https://bitnami.com/assets/stacks/redis/img/redis-stack-220x234.png
sources:
- https://github.com/bitnami/bitnami-docker-redis
maintainers: []
engine: gotpl
`
}

function quoted (str) {return `"${str}"`}

test("versions are properly quoted when they look like integers", () => {
    // version 1.4 could be an integer, so it should be quoted as a string
    const [oldVersion, newVersion] = ['1.3', '1.4']
    
    const givenYAML = createChart(quoted(oldVersion), quoted(oldVersion));
    const expectedYAML = createChart(quoted(newVersion), quoted(newVersion))

    const {newYAML} = bumpChartVersion(givenYAML, newVersion, newVersion);

    expect(newYAML).toEqual(expectedYAML)
});

test("bumping to the same version does not give any changes", () => {
    const [chartVersion, appVersion] = ['1.33.7', '13.3.7'];

    const givenYAML = createChart(chartVersion, appVersion);

    const {changes, newYAML} = bumpChartVersion(givenYAML, chartVersion, appVersion);

    expect(changes.length).toBe(0);
    expect(newYAML).toEqual(givenYAML);
});

test("changing chartVersion only changes the chartVersion", () => {
    const [oldChartVersion, newChartVersion,  appVersion] = ['1.33.7', '1.38', '13.3.7'];

    const givenYAML = createChart(oldChartVersion, appVersion);
    const expectedYAML = createChart(quoted(newChartVersion), appVersion);
    
    const {changes, newYAML} = bumpChartVersion(givenYAML, newChartVersion, appVersion);

    expect(changes.length).toBe(1);
    expect(newYAML).toEqual(expectedYAML);
});

test("changing both chartVersion and appVersion", () => {
    const [oldChartVersion, newChartVersion] = ['1.33.7', '1.21.38'];
    const [oldAppVersion, newAppVersion] = ['0.1', '0.2'];
    
    const givenYAML = createChart(oldChartVersion, quoted(oldAppVersion));
    const expectedYAML = createChart(newChartVersion, quoted(newAppVersion));
    
    const {changes, newYAML} = bumpChartVersion(givenYAML, newChartVersion, newAppVersion);

    expect(changes.length).toBe(2);
    expect(newYAML).toEqual(expectedYAML);
});