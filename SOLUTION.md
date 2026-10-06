# Solution

> **AI disclosure:** built with Claude Code as a pair-programming assistant. Design decisions are mine, and
> everything was verified locally on kind.

## 1. How to run and verify the setup locally?

Prerequisites: Docker, `kind`, `kubectl`, `helm`, `skaffold`.

```bash
docker build -f docker/php-fpm/Dockerfile -t legacy-web-php-fpm .
docker build -f docker/nginx/Dockerfile -t legacy-web-nginx .
```

Skaffold builds the images, loads them into kind and runs `helm install` for metrics-server, External Secrets
Operator and `helm/legacy-web` with `kind/values.yaml`:

```bash
kind create cluster --config kind/cluster.yaml
skaffold run
```

```bash
kubectl get pods,svc,ingress,hpa,pdb,networkpolicy,secretstore,externalsecret
kubectl port-forward svc/legacy-web 8080:80 &
sleep 2
curl localhost:8080/
curl localhost:8080/healthz
curl localhost:8080/readyz
kubectl logs deploy/legacy-web -c nginx
kill %1
```

```bash
skaffold delete
kind delete cluster --name legacy-web
```

## 2. Observability strategy

- kube-prometheus-stack + Loki + Fluent Bit: small footprint, Grafana as one UI for metrics and logs
- Logs: Fluent Bit ships container stdout/stderr with Kubernetes metadata to Loki (S3 storage)
- Metrics: Prometheus with nginx and php-fpm exporter sidecars; FPM pool metrics size `pm.max_children` and the HPA
- Alerting: `PrometheusRule`s on 5xx rate, latency, HPA at max, FPM queue, restarts
- Later: OpenTelemetry tracing to Tempo; Sentry for PHP errors and Better Stack/Checkly for external uptime checks

## 3. Production considerations

- GitOps with Argo CD: Terraform creates only AWS resources + bootstraps argocd, which will take over self-management and applications' deployments
- Supply chain: SBOM (if needed), cosign signing, deploy by digest, Kyverno admits only signed images
- Edge: CloudFront + AWS WAF in front of the ALB
- Security: Pod Security Admission `restricted`, namespace default-deny NetworkPolicy, private EKS endpoint, KMS for Secrets Manager. Trivy runtime scanner
- Environments: Terragrunt `live/<env>` and per-environment Argo CD values, plans reviewed in CI
- Capacity: load test to size requests, limits and `pm.max_children`

## Design decisions

- nginx + php-fpm as two containers in one pod: one process each, FPM only on `127.0.0.1:9000`
- Non-root, read-only root filesystem, all capabilities dropped; logs to stdout/stderr
- Readiness `/readyz` through nginx, liveness per container; `preStop` sleep gives zero dropped requests during rollouts
- Config in a ConfigMap, credentials via External Secrets Operator from AWS Secrets Manager
- No static AWS keys: EKS Pod Identity gives ESO a role that can read only `legacy-web/db`
- HA: 2–10 replicas with HPA, PDB, topology spread across nodes and zones
- NetworkPolicy: ingress on 8080, egress only to DNS and DB/cache
- EKS Auto Mode: AWS manages nodes, ALB controller and networking
- CI: native amd64 and arm64 builds, smoke test and Trivy scan; multi-arch images to GHCR; Trivy misconfiguration scan of the chart
- Renovate keeps images, charts, modules and providers up to date

## Not done

- Terraform not applied (no AWS account); validated offline with mocked dependencies
- CI not run on GitHub yet; checks run locally
- Ingress not tested locally (kind has no ALB)
