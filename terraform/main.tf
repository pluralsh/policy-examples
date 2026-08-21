terraform {
  required_version = ">= 1.5.0"

  required_providers {
    plural = {
      source  = "pluralsh/plural"
      version = "~> 0.2.39"
    }
  }
}

provider "plural" {}

data "plural_project" "project" {
  name = "default"
}
