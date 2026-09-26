vpcs = {
  vpc_a = {
    networking_config = {
      vpc_cidr         = "10.0.0.0/16"
      subnet_count     = 3
      pub_subnets      = ["10.0.0.0/24", "10.0.2.0/24", "10.0.4.0/24"]
      priv_subnets     = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
      dns_support      = true
      hostname_support = true
      tenancy          = "default"
    }
  }

}