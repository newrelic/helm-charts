TMP_DIRECTORY = ./tmp
CHARTS ?= nr-k8s-otel-collector

.PHONY: generate-examples
generate-examples:
	for chart_name in $(CHARTS); do \
  		make install-helm-dependencies -C charts/$${chart_name}; \
		helm dependency build charts/$${chart_name}; \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			echo "Generating example: $${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			rm -rf "$${EXAMPLES_DIR}/$${example}/rendered"; \
			for value in $${VALUES}; do \
				helm template "$${chart_name}" charts/$${chart_name} --namespace newrelic --set licenseKey='<NR_licenseKey>' --set cluster='<cluser_name>' --values $${value} --output-dir "$${EXAMPLES_DIR}/$${example}/rendered"; \
				mv $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered"; \
				SUBCHARTS_DIR=$${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/charts; \
				if [ -d "$${SUBCHARTS_DIR}" ]; then \
					SUBCHARTS=$$(find $${SUBCHARTS_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
					for subchart in $${SUBCHARTS}; do \
						mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/$${subchart}"; \
						mv $${SUBCHARTS_DIR}/$${subchart}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered/$${subchart}"; \
					done; \
				fi; \
				rm -rf $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}; \
			done; \
		done; \
	done

HELM_DOCS ?= go run github.com/norwoodj/helm-docs/cmd/helm-docs@latest
.PHONY: generate-nr-k8s-chart-docs
generate-nr-k8s-chart-docs:
	$(HELM_DOCS) -c charts/nr-k8s-otel-collector
