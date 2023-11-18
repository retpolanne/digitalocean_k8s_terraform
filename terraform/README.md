# TODO

- Superset configured with datasource for postgres
- Superset secret change and init admin user
- Setup dashboards programatically (importing them?)

# Applying Terraform

```sh
terraform apply --var digitalocean_token=$DO_ACCESS_TOKEN --var digitalocean_access_id=$AWS_ACCESS_KEY_ID --var digitalocean_secret_key=$AWS_SECRET_ACCESS_KEY
```

# Accessing superset 

```sh
doctl kubernetes cluster kubeconfig save $CLUSTER_ID
k port-forward service/superset 8088:8088
```

# Importing hledger journal to psql

```sh
k port-forward service/psql-postgresql 5432:5432
hledger2psql -f ~/.hledger.journal --db-url postgresql://postgres:${PSQL_PASSWORD}@localhost:5432 -t hledger
```
