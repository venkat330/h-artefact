terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

variable "deployment_type" {
  type        = string
  description = "Deployment type"
  default     = "custom"
}

variable "build_base" {
  type        = string
  description = "Image path"
  default     = "python"
}

variable "build_version" {
  type        = string
  description = "Image version"
  default     = "3.10"
}
# Configure the GitHub Provider
provider "github" {
  token = ""
}

data "github_repository_file" "dockerfile" {
  repository = replace("h-artefact", "venkat330/", "")
  file       = "harness/Dockerfile.${var.deployment_type}"
}

locals {
  build_base         = var.build_base
  build_version      = var.build_version
  dockerfile_content = replace(data.github_repository_file.dockerfile.content, "/\\$\\{base\\}:\\$\\{version\\}/", "${local.build_base}:${local.build_version}")
}


resource "github_repository" "repo" {
  name        = "h-artefact-clone"
  description = "My awesome codebase"
  visibility  = "public"

  template {
    owner                = "venkat330"
    repository           = "h-artefact"
    include_all_branches = false
  }
}

data "github_branch" "main" {
  repository  = github_repository.repo.name
  branch     = "main"
}
# data "github_release" "code" {
#   repository  = "h-artefact"
#   owner       = "venkat330"
#   retrieve_by = "latest"
# }

resource "github_repository_file" "remove_config" {
  repository          = replace(github_repository.repo.name, "venkat330/", "")
  file                = "myconfig"
  content             = ""
  branch              = "main"
  overwrite_on_create = true
  commit_message      = "test"
}

output "name" {
  value = data.github_branch.main
}

output "new_repo" {
  value = github_repository.repo
}

resource "github_repository_file" "Dockerfile_base" {
  repository          = replace(github_repository.repo.name, "venkat330/", "")
  file                = "Dockerfile.base"
  content             = ""
  branch              = "main"
  overwrite_on_create = true
}


resource "github_repository_file" "Dockerfile" {
  repository          = replace(github_repository.repo.name, "venkat330/", "")
  file                = "Dockerfile"
  content             = local.dockerfile_content
  branch              = "main"
  overwrite_on_create = true
}
