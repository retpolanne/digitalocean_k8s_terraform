# superset_hledger repo terraform

This terraform creates the superset_hledger repo. Should be used only once in a separate workspace.

**TODO** create repo only for creating repos on github

## Encrypting secrets for Github Actions variables

```sh
gh secret set secret_name --no-store
# Example
gh secret set AWS_ACCESS_KEY_ID --no-store
```

## Applying

```sh
terraform plan --var-file=secrets.tfvars
```
