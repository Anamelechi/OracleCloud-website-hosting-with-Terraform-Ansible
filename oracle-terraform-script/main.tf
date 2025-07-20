# Configure the Oracle Cloud Infrastructure Provider
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Data source to get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Data source for ARM-based Ubuntu images
data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Data source for x86 Ubuntu images
data "oci_core_images" "ubuntu_images_x86" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create VCN (Virtual Cloud Network)
resource "oci_core_vcn" "main_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "main-vcn"
  dns_label      = "mainvcn"
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "main_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "main-internet-gateway"
}

# Create Route Table
resource "oci_core_route_table" "main_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "main-route-table"
  
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main_igw.id
  }
}

# Create Security List
resource "oci_core_security_list" "main_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "main-security-list"
  
  # Allow outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  
  # Allow SSH (port 22)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 22
      max = 22
    }
  }
  
  # Allow HTTP (port 80)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 80
      max = 80
    }
  }
  
  # Allow HTTPS (port 443)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 443
      max = 443
    }
  }
  
  # Allow Cloudflared tunnel (port 7844)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 7844
      max = 7844
    }
  }
}

# Create Public Subnet
resource "oci_core_subnet" "main_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.main_vcn.id
  cidr_block          = "10.0.1.0/24"
  display_name        = "main-public-subnet"
  dns_label           = "mainsubnet"
  route_table_id      = oci_core_route_table.main_route_table.id
  security_list_ids   = [oci_core_security_list.main_security_list.id]
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.preferred_ad].name
}

# Create Compute Instance (ARM-based A1.Flex)
resource "oci_core_instance" "main_instance" {
  count               = var.use_x86_fallback ? 0 : 1
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.preferred_ad].name
  compartment_id      = var.compartment_ocid
  display_name        = "main-instance"
  shape               = "VM.Standard.A1.Flex"
  
  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }
  
  create_vnic_details {
    subnet_id        = oci_core_subnet.main_subnet.id
    display_name     = "main-vnic"
    assign_public_ip = true
  }
  
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_images.images[0].id
  }
  
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
  
  preserve_boot_volume = false
  
  # Add lifecycle rule to prevent destruction
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      source_details[0].source_id,
    ]
  }
}

# Create Compute Instance (x86 fallback)
resource "oci_core_instance" "main_instance_x86" {
  count               = var.use_x86_fallback ? 1 : 0
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.preferred_ad].name
  compartment_id      = var.compartment_ocid
  display_name        = "main-instance-x86"
  shape               = "VM.Standard.E2.1.Micro"
  
  # No shape_config needed for micro instance
  
  create_vnic_details {
    subnet_id        = oci_core_subnet.main_subnet.id
    display_name     = "main-vnic-x86"
    assign_public_ip = true
  }
  
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_images_x86.images[0].id
  }
  
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
  
  preserve_boot_volume = false
}

# Create Block Volume
resource "oci_core_volume" "main_volume" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.preferred_ad].name
  compartment_id      = var.compartment_ocid
  display_name        = "main-block-volume"
  size_in_gbs         = 100
}

# Attach Block Volume to Instance (ARM)
resource "oci_core_volume_attachment" "main_volume_attachment" {
  count           = var.use_x86_fallback ? 0 : 1
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.main_instance[0].id
  volume_id       = oci_core_volume.main_volume.id
  display_name    = "main-volume-attachment"
}

# Attach Block Volume to Instance (x86)
resource "oci_core_volume_attachment" "main_volume_attachment_x86" {
  count           = var.use_x86_fallback ? 1 : 0
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.main_instance_x86[0].id
  volume_id       = oci_core_volume.main_volume.id
  display_name    = "main-volume-attachment-x86"
}