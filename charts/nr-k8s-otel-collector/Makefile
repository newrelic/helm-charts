.PHONY: generate-examples
install-helm-dependencies:
	echo 'Installing Helm Dependencies nr-k8s-otel-collector-> prometheus-community...'; \
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

NEWRELIC_E2E ?= go run github.com/newrelic/newrelic-integration-e2e-action@latest
.PHONY: e2e-test
e2e-test:
	$(NEWRELIC_E2E) \
		--commit_sha=test-string \
		--retry_attempts=10 \
		--retry_seconds=60 \
		--account_id=${ACCOUNT_ID} \
		--api_key=${API_REST_KEY} \
		--license_key=${LICENSE_KEY} \
		--spec_path=./e2e/test-specs.yml \
		--verbose_mode=true \
		--agent_enabled="false"
