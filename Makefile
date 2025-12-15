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
				helm template "$${chart_name}" charts/$${chart_name} --namespace newrelic --include-crds --set licenseKey='<NR_licenseKey>' --set cluster='<cluser_name>' --values $${value} --output-dir "$${EXAMPLES_DIR}/$${example}/rendered"; \
				CHART_OUTPUT_DIR="$${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}"; \
				\
				mv $${CHART_OUTPUT_DIR}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered"; \
				[ -d "$${CHART_OUTPUT_DIR}/crds" ] && mv $${CHART_OUTPUT_DIR}/crds/* "$${EXAMPLES_DIR}/$${example}/rendered" || true; \
				\
				CHARTS_DIR=$${CHART_OUTPUT_DIR}/charts; \
				if [ -d "$${CHARTS_DIR}" ]; then \
					for subchart_dir in $${CHARTS_DIR}/*; do \
						[ ! -d "$$subchart_dir" ] && continue; \
						subchart=$$(basename $$subchart_dir); \
						\
						if [ "$$subchart" = "opentelemetry-kube-stack" ]; then \
							mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/opentelemetry-kube-stack"; \
							[ -d "$$subchart_dir/templates" ] && mv $$subchart_dir/templates/* "$${EXAMPLES_DIR}/$${example}/rendered/opentelemetry-kube-stack" || true; \
							[ -d "$$subchart_dir/crds" ] && mv $$subchart_dir/crds/* "$${EXAMPLES_DIR}/$${example}/rendered/opentelemetry-kube-stack" || true; \
							\
							NESTED_CHARTS="$$subchart_dir/charts"; \
							if [ -d "$$NESTED_CHARTS" ]; then \
								if [ -d "$$NESTED_CHARTS/opentelemetry-operator/templates" ]; then \
									mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/opentelemetry-operator"; \
									mv $$NESTED_CHARTS/opentelemetry-operator/templates/* "$${EXAMPLES_DIR}/$${example}/rendered/opentelemetry-operator" || true; \
								fi; \
								if [ -d "$$NESTED_CHARTS/opentelemetry-operator/crds" ]; then \
									mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/crds"; \
									mv $$NESTED_CHARTS/opentelemetry-operator/crds/* "$${EXAMPLES_DIR}/$${example}/rendered/crds" || true; \
								fi; \
								if [ -d "$$NESTED_CHARTS/otel-crds/crds" ]; then \
									mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/crds"; \
									mv $$NESTED_CHARTS/otel-crds/crds/* "$${EXAMPLES_DIR}/$${example}/rendered/crds" || true; \
								fi; \
							fi; \
						else \
							mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/$$subchart"; \
							[ -d "$$subchart_dir/templates" ] && mv $$subchart_dir/templates/* "$${EXAMPLES_DIR}/$${example}/rendered/$$subchart" || true; \
							[ -d "$$subchart_dir/crds" ] && mv $$subchart_dir/crds/* "$${EXAMPLES_DIR}/$${example}/rendered/$$subchart" || true; \
						fi; \
					done; \
				fi; \
				rm -rf $${CHART_OUTPUT_DIR}; \
			done; \
		done; \
	done
	@echo "Sanitizing rendered examples to remove sensitive data..."
	@$(MAKE) sanitize-rendered-examples

.PHONY: sanitize-rendered-examples
sanitize-rendered-examples:
	@for chart_name in $(CHARTS); do \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			RENDERED_DIR="$${EXAMPLES_DIR}/$${example}/rendered"; \
			if [ -d "$$RENDERED_DIR" ]; then \
				echo "Sanitizing rendered templates in: $$RENDERED_DIR"; \
				find "$$RENDERED_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) | while read file; do \
					if grep -q "caBundle:" "$$file" 2>/dev/null; then \
						sed -i '' 's/caBundle: LS[A-Za-z0-9+/=]*/caBundle: CERTIFICATE_BASE64/g' "$$file"; \
						echo "  ✓ Sanitized caBundle in: $$file"; \
					fi; \
					if grep -q "bearerToken:" "$$file" 2>/dev/null; then \
						sed -i '' 's/bearerToken: "[^"]*"/bearerToken: "DUMMY_TOKEN_PLACEHOLDER"/g' "$$file"; \
						echo "  ✓ Sanitized bearerToken in: $$file"; \
					fi; \
					if grep -q "tls\.crt:" "$$file" 2>/dev/null; then \
						sed -i '' 's/tls\.crt: LS[A-Za-z0-9+/=]*/tls.crt: CERTIFICATE_BASE64/g' "$$file"; \
						echo "  ✓ Sanitized tls.crt in: $$file"; \
					fi; \
					if grep -q "tls\.key:" "$$file" 2>/dev/null; then \
						sed -i '' 's/tls\.key: LS[A-Za-z0-9+/=]*/tls.key: KEY_BASE64/g' "$$file"; \
						echo "  ✓ Sanitized tls.key in: $$file"; \
					fi; \
					if grep -q "ca\.crt:" "$$file" 2>/dev/null; then \
						sed -i '' 's/ca\.crt: LS[A-Za-z0-9+/=]*/ca.crt: CERTIFICATE_BASE64/g' "$$file"; \
						echo "  ✓ Sanitized ca.crt in: $$file"; \
					fi; \
				done; \
				echo "  ✓ Sanitization complete for: $$example"; \
			fi; \
		done; \
	done

HELM_DOCS ?= go run github.com/norwoodj/helm-docs/cmd/helm-docs@latest
.PHONY: generate-nr-k8s-chart-docs
generate-nr-k8s-chart-docs:
	$(HELM_DOCS) -c charts/nr-k8s-otel-collector
