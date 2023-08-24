terraform {
  backend "azurerm" {
    resource_group_name   = "NetworkWatcherRG"
    storage_account_name  = "tfstoragelinux"
    container_name        = "linux-container"
    key                   = "terraform.tfstate"
     
  }
}
