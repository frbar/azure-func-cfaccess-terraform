resource "cloudflare_access_application" "poc" {
  zone_id                   = var.cf_zone_id
  name                      = "Application - ${var.env_name}"
  domain                    = "${var.env_name}.${var.cf_domain}"
  type                      = "self_hosted"
  session_duration          = "1h"
  auto_redirect_to_identity = false
  app_launcher_visible      = false
}

resource "cloudflare_access_policy" "poc" {
  application_id = cloudflare_access_application.poc.id
  zone_id        = var.cf_zone_id
  name           = "email policy"
  precedence     = "1"
  decision       = "allow"

  include {
    email_domain = [ var.email_domain ]
  }

  require {
    email_domain = [ var.email_domain ]
  }
}