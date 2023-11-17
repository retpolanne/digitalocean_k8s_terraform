output "repo_origin" {
  value = "git@github.com:${data.github_user.current.login}/${github_repository.digitalocean_k8s.name}.git"
}
