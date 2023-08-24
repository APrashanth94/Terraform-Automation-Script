terraform {
  required_providers {
    azurerm = {
      version = "= 3.69.0"
    }
  }
}


provider "azurerm"{
skip_provider_registration = true
subscription_id = "1851fed6-7a4a-400e-9e4b-4b7551d5fa2e"
client_id = "46cb8ef5-23ff-4dd3-8957-053f3fdc33bf"
client_secret = "zHL8Q~5xKGA5ur-2zNSWC.qTMk4FhiphRF1gEbyE"
tenant_id = "2cc21ac3-73a9-429e-baef-7ae2a0a272ac"
features {}
}
