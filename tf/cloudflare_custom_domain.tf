resource "cloudflare_record" "cname" {
  zone_id         = var.cf_zone_id
  name            = var.env_name
  type            = "CNAME"
  value           = azurerm_windows_function_app.poc.default_hostname
  proxied         = false
  allow_overwrite = true
  lifecycle {
    ignore_changes = [
      # Needs to be false on first run for domain validation.
      proxied,
    ]
  }
}

resource "cloudflare_record" "txt" {
  zone_id         = var.cf_zone_id
  name            = "asuid.${cloudflare_record.cname.name}"
  type            = "TXT"
  value           = azurerm_windows_function_app.poc.custom_domain_verification_id
  allow_overwrite = true
}

resource "time_sleep" "wait_for_txt" {
  depends_on = [
    cloudflare_record.txt
  ]

  create_duration = "60s"
}

resource "azurerm_app_service_custom_hostname_binding" "poc" {
  hostname            = cloudflare_record.cname.hostname
  app_service_name    = azurerm_windows_function_app.poc.name
  resource_group_name = var.rg_name
  depends_on = [
    time_sleep.wait_for_txt
  ]
}

resource "azurerm_app_service_managed_certificate" "poc" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.poc.id

  # Once this is created, we can set the cloudflare proxy correctly
  # https://api.cloudflare.com/#dns-records-for-a-zone-patch-dns-record
  provisioner "local-exec" {
    command = <<-EOT
      $headers = @{ 
                    "Authorization" = "Bearer ${var.cf_api_token}"  
                    "Content-Type"  = "application/json"
	                }
      $body = @{ 
                  proxied = $true 
                } | ConvertTo-Json

      Invoke-RestMethod -Method Patch `
                        -Uri "https://api.cloudflare.com/client/v4/zones/${var.cf_zone_id}/dns_records/${cloudflare_record.cname.id}" `
                        -Headers $headers `
                        -Body $body
      EOT
    interpreter = ["PowerShell", "-Command"]
  }
}

resource "azurerm_app_service_certificate_binding" "poc" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.poc.id
  certificate_id      = azurerm_app_service_managed_certificate.poc.id
  ssl_state           = "SniEnabled"
}