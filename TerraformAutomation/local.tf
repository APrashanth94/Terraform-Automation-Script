variable "csv_folder" {
  description = "Path to the folder containing CSV files"
  default     = "CSVFiles"
}

variable "csv_files" {
  description = "List of CSV files in the folder"
  default     = ["linux.csv", "windows.csv", "linux-2.csv"] 
}

locals {
  csv_data = flatten([
    for csv_file in var.csv_files :
    csvdecode(file("${path.module}/${var.csv_folder}/${csv_file}"))
  ])
}

locals {
  format_csv_data = [
    for row in local.csv_data :
    {
      resourcegroup           = row["resourcegroup"]
      location                = row["location"]
      virtualMachineName      = row["virtualMachineName"]
      virtualMachineSize      = row["virtualMachineSize"]
      virtualNetworkName      = row["virtualNetworkName"]
      vnetAddressPrefixes     = row["vnetAddressPrefixes"]
      subnetName              = row["subnetName"]
      snetAddressPrefixes     = row["snetAddressPrefixes"]
      nsgName                 = row["nsgName"]  
      nsg_rules               = jsondecode(row["nsg_rules"]) 
    }
  ]
}


locals {
  format_csv_data_map = {
    for idx, row in local.format_csv_data : idx => row
  }
}

