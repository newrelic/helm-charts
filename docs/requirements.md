# Requirements

Contributions to this repository must adhere to the following technical and documentation requirements.

### Technical requirements

* Must submit all chart dependencies separately.
* Must pass the linter (`helm lint`).
* Must successfully launch with default values (`helm install .`).
    * All pods go to the running state (or `NOTES.txt` provides further instructions if a required value is missing).
    * All services have at least one endpoint.
* Must include source GitHub repositories for images used in the chart.
* Images should not have any major security vulnerabilities.
* Must be up-to-date with the latest stable Helm/Kubernetes features.
    * Use Deployments instead of ReplicationControllers.
* Should follow Kubernetes best practices.
    * Include Health Checks wherever practical.
    * Allow configurable [resource requests and limits](http://kubernetes.io/docs/user-guide/compute-resources/#resource-requests-and-limits-of-pod-and-container).
* Provide a method for data persistence (if applicable).
* Support application upgrades.
* Allow customization of the application configuration.
* Provide a secure default configuration.
* Do not leverage alpha features of Kubernetes.
* Follow [best practices](https://helm.sh/docs/chart_best_practices/)  (especially for [labels](https://helm.sh/docs/chart_best_practices/labels/) and [values](https://helm.sh/docs/chart_best_practices/values/)).

### Documentation requirements

* Must include an in-depth `README.md`, including:
    * Short description of the chart
    * Any prerequisites/requirements
    * Customization options in `values.yaml` and their defaults
* Must include a short [NOTES.txt](https://helm.sh/docs/topics/charts/#chart-license-readme-and-notes), including:
    * Any relevant post-install information for the chart
    * Instructions on how to access the application or service provided by the chart