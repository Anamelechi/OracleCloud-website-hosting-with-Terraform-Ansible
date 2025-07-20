# Output the public IP address
output "public_ip" {
  value = var.use_x86_fallback ? (
    length(oci_core_instance.main_instance_x86) > 0 ? oci_core_instance.main_instance_x86[0].public_ip : null
  ) : (
    length(oci_core_instance.main_instance) > 0 ? oci_core_instance.main_instance[0].public_ip : null
  )
}

# Output the instance OCID
output "instance_ocid" {
  value = var.use_x86_fallback ? (
    length(oci_core_instance.main_instance_x86) > 0 ? oci_core_instance.main_instance_x86[0].id : null
  ) : (
    length(oci_core_instance.main_instance) > 0 ? oci_core_instance.main_instance[0].id : null
  )
}