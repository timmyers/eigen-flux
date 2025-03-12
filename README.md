# eigen-flux

This repository contains Terraform configuration for managing a Kubernetes cluster on DigitalOcean, with ArgoCD installed for GitOps deployment management of the sister repo: [eigen-service](https://github.com/timmyers/eigen-service)

## ArgoCD

You can find the Argo deployment [here](https://argo.eigen.tmye.me/login?return_url=https%3A%2F%2Fargo.eigen.tmye.me%2Fapplications),
but it is password protected.

## Eigen Service Dev env:
```
manifests/eigen-service
eigen_service.tf
```
Live at [https://eigen.tmye.me](https://eigen.tmye.me)

## Eigen Service PR review env:
```
manifests/eigen-service-review
eigen_service_reciew_apps.tf
```
PR: https://github.com/timmyers/eigen-service/pull/2
Live at [https://feat-super-cool.eigen-review.tmye.me](https://feat-super-cool.eigen-review.tmye.me)
