#!/bin/bash

# OCI ARM Instance Retry Script
# This script tries to create an ARM instance across different availability domains and regions

set -e

# Configuration
REGIONS=("eu-milan-1" "eu-frankfurt-1" "eu-amsterdam-1" "us-phoenix-1" "us-ashburn-1")
AVAILABILITY_DOMAINS=(0 1 2)
MAX_RETRIES=5
RETRY_DELAY=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if instance exists
check_instance() {
    terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "oci_core_instance") | .values.lifecycle_state' 2>/dev/null || echo "NOT_FOUND"
}

# Function to try creating instance with specific region and AD
try_create_instance() {
    local region=$1
    local ad=$2
    local attempt=$3
    
    log_info "Attempt $attempt: Trying region $region, availability domain $ad"
    
    # Update terraform.tfvars with new region and AD
    sed -i.bak "s/region = .*/region = \"$region\"/" terraform.tfvars
    sed -i.bak "s/preferred_ad = .*/preferred_ad = $ad/" terraform.tfvars
    
    # Try to apply
    if terraform apply -auto-approve -var="region=$region" -var="preferred_ad=$ad"; then
        log_info "SUCCESS: Instance created in region $region, availability domain $ad"
        return 0
    else
        log_error "FAILED: Could not create instance in region $region, availability domain $ad"
        return 1
    fi
}

# Function to cleanup failed attempts
cleanup() {
    log_warn "Cleaning up failed attempt..."
    terraform destroy -auto-approve || true
    sleep 10
}

# Main retry logic
main() {
    log_info "Starting OCI ARM instance creation with retry logic..."
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        log_error "terraform.tfvars not found. Please create it first."
        exit 1
    fi
    
    # Initialize terraform
    terraform init
    
    local success=false
    local total_attempts=0
    
    # Try different regions and availability domains
    for region in "${REGIONS[@]}"; do
        for ad in "${AVAILABILITY_DOMAINS[@]}"; do
            for retry in $(seq 1 $MAX_RETRIES); do
                total_attempts=$((total_attempts + 1))
                
                if try_create_instance "$region" "$ad" "$total_attempts"; then
                    success=true
                    break 3  # Break out of all loops
                fi
                
                cleanup
                
                if [ $retry -lt $MAX_RETRIES ]; then
                    log_warn "Retrying in $RETRY_DELAY seconds..."
                    sleep $RETRY_DELAY
                fi
            done
        done
    done
    
    if [ "$success" = true ]; then
        log_info "Instance successfully created!"
        terraform output
    else
        log_error "Failed to create instance after $total_attempts attempts across all regions and availability domains."
        log_error "Try again later or consider using a different approach."
        exit 1
    fi
}

# Trap to cleanup on script exit
trap cleanup EXIT

# Run main function
main "$@"
/mnt/c/Users/philz/Desktop/oci-key