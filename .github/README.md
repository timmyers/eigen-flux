# GitHub Actions Terraform Cloud Setup Guide

This document explains how to set up the GitHub Actions workflow for this Terraform repository.

## Required Secrets

You need to configure the following secrets in your GitHub repository:

1. `TF_API_TOKEN`: A Terraform Cloud API token with permission to manage workspaces

## Creating a Terraform Cloud API Token

1. Log in to Terraform Cloud (https://app.terraform.io)
2. Go to User Settings > Tokens
3. Create an API token
4. Copy the token value

## Configuring GitHub Secrets

1. Navigate to your GitHub repository
2. Go to Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Add the secret:
   - Name: `TF_API_TOKEN`
   - Value: (paste your token)
5. Click "Add secret"

## Configuring Terraform Cloud

1. Create an organization in Terraform Cloud (if you don't have one)
2. Create a workspace named "eigen-flux"
3. In your workspace settings, set the execution mode to "Remote"
4. Configure any required variables in the Terraform Cloud workspace:
   - `do_token` (mark as sensitive)
   - Any other variables needed for your infrastructure

## Update Configuration

Make sure to update the workflow file and main.tf with your actual Terraform Cloud organization name:
- In `.github/workflows/terraform.yml`: Update the `TF_CLOUD_ORGANIZATION` value
- In `main.tf`: Update the `organization` value in the cloud block