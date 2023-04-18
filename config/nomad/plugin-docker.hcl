plugin "docker" {
  config {
    allow_privileged = true
    allow_caps = ["all"]
    volumes {
      enabled = true
    }
  }
}
