# Amazon AMI Support for Guix - Project Plan

## Overview

This project adds support for building Amazon AMI images from Guix System definitions for deployment on AWS EC2, leveraging Guix's existing image building infrastructure and integrating with cuirass CI/CD.

**Timeline**: 6-8 weeks
**Beads Binary**: Installed at `/usr/local/bin/bd` (v0.21.7)

---

## Project Structure

### Main Epic: Amazon AMI Support for Guix
**Priority**: P0
**Type**: Epic
**Description**: Implement support for building Amazon AMI images from Guix System definitions for deployment on AWS EC2. This includes creating image types, cloud-init integration, and cuirass CI/CD support.

---

## Phase 1: Core AMI Image Support
**Priority**: P0
**Type**: Epic
**Description**: Create AWS image module, implement cloud initialization, and verify kernel configuration for EC2 compatibility

### Tasks

1. **Create gnu/system/images/aws.scm module** (P0, Task)
   - Define AWS image module with EC2-optimized operating system configuration including GRUB bootloader, kernel arguments (console=ttyS0), and file system layout

2. **Define aws-ec2-os base configuration** (P0, Task)
   - Create base operating system configuration with: UTC timezone, GRUB EFI bootloader, serial console output, ext4 root filesystem, EFI system partition, DHCP networking, and OpenSSH service

3. **Implement EC2 metadata service integration** (P1, Task)
   - Create Shepherd service or integrate cloud-init for EC2 metadata service. Must fetch SSH keys from http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key and handle IMDSv2 token-based authentication

4. **Create AMI image type definitions** (P1, Task)
   - Define image types: aws-ami-x86-64-uefi-image-type (primary), aws-ami-x86-64-bios-image-type (legacy), aws-ami-aarch64-uefi-image-type (Graviton). Each should specify partition table, bootloader, and platform

5. **Create concrete AMI image definitions for CI** (P1, Task)
   - Define aws-barebones-ami-image variants (x86_64 UEFI, x86_64 BIOS, aarch64) with appropriate size (10GB), platform, and OS configuration for cuirass builds

6. **Verify kernel driver support for EC2** (P2, Task)
   - Verify linux-libre includes: ENA (Elastic Network Adapter), NVMe drivers for EBS, Xen drivers, KVM/virtio drivers. Create linux-libre-ec2 variant if needed

7. **Test local build with guix system image** (P2, Task)
   - Build AMI image locally using 'guix system image' command and verify output format, partition structure, and file system layout

**Dependencies**: Phase 2 blocks on Phase 1

---

## Phase 2: Testing & Validation
**Priority**: P0
**Type**: Epic
**Description**: Local testing with QEMU, AWS import and testing on actual EC2 instances

### Tasks

1. **Test boot in QEMU with UEFI firmware** (P0, Task)
   - Test AMI image boot using qemu-system-x86_64 with OVMF firmware, verify serial console output (console=ttyS0), network via DHCP, and SSH service startup

2. **Upload test image to S3** (P1, Task)
   - Upload built AMI image to S3 bucket using AWS CLI. Create bucket if needed and verify upload integrity

3. **Import as AMI using VM Import/Export** (P1, Task)
   - Create containers.json with raw format specification, run aws ec2 import-image with correct platform, architecture, and boot-mode parameters

4. **Launch test EC2 instance** (P1, Task)
   - Launch EC2 instance from imported AMI. Test on t3.micro (Nitro/KVM), verify instance launches and reaches running state

5. **Verify SSH access with EC2 key pair** (P1, Task)
   - Test SSH access using EC2 key pair. Verify metadata service correctly injects public key to /root/.ssh/authorized_keys

6. **Verify serial console output in AWS Console** (P2, Task)
   - Enable serial console access in AWS Console and verify boot messages are visible via console=ttyS0 output

7. **Test guix pull and guix system reconfigure** (P2, Task)
   - SSH into instance and verify: guix pull works, guix system reconfigure can update the system, substitutes are fetched correctly

8. **Test on multiple instance types** (P2, Task)
   - Test AMI on: t3.micro (Nitro/KVM), t2.micro (Xen legacy), t4g.micro (ARM64 Graviton), m5.large (ENA driver). Verify compatibility across generations

**Dependencies**: Phase 3 blocks on Phase 2

---

## Phase 3: Cuirass CI Integration
**Priority**: P1
**Type**: Epic
**Description**: Add AWS images to CI build jobs for automated building on ci.guix.gnu.org

### Tasks

1. **Add AWS images to %guix-system-images in gnu/ci.scm** (P1, Task)
   - Add aws-barebones-ami-x86-64-image and aws-barebones-ami-aarch64-image to the %guix-system-images list for CI builds

2. **Configure image-jobs function for AWS images** (P1, Task)
   - Update image-jobs function to build AWS images when system is x86_64-linux. Use image->job to create build jobs with appropriate naming

3. **Set build parameters for CI** (P2, Task)
   - Configure: image size (10-20 GB), no compression (raw format required), substitutability enabled for faster builds

4. **Verify automated builds on ci.guix.gnu.org** (P2, Task)
   - Monitor cuirass to verify AWS AMI images build successfully in CI. Check build logs and artifacts

**Dependencies**: None (Phase 4 can run in parallel)

---

## Phase 4: Tooling & Documentation
**Priority**: P1
**Type**: Epic
**Description**: Helper scripts for AWS operations and comprehensive user documentation

### Tasks

1. **Create guix system aws-upload command** (P2, Task)
   - Implement helper command to upload AMI images to S3 with parameters: --image, --bucket, --region, --description

2. **Create guix system aws-import command** (P2, Task)
   - Implement helper command to import S3 images as AMIs with parameters: --bucket, --key, --architecture, --boot-mode, --region

3. **Create guix system aws-publish command** (P2, Task)
   - Implement helper command to register and share AMIs across regions and accounts

4. **Write Quick Start Guide in doc/guix.texi** (P2, Task)
   - Document: how to build AMIs locally, upload/import to AWS, launch instances, customize OS configuration

5. **Create example configurations in gnu/system/examples/** (P2, Task)
   - Add example AWS configurations: basic web server AMI, development environment AMI, high-availability setup

6. **Write troubleshooting section** (P2, Task)
   - Document common issues: boot problems, network issues, SSH access problems, serial console debugging

7. **Write architecture reference documentation** (P2, Task)
   - Document: how AMI building works, EC2-specific services, kernel requirements, instance type compatibility matrix

---

## Task Summary

- **Total Epics**: 5 (1 main + 4 phases)
- **Total Tasks**: 26
  - Phase 1: 7 tasks
  - Phase 2: 8 tasks
  - Phase 3: 4 tasks
  - Phase 4: 7 tasks

## Dependency Graph

```
Amazon AMI Support (Main Epic)
├─ blocks on → Phase 1: Core AMI Image Support
├─ blocks on → Phase 2: Testing & Validation
├─ blocks on → Phase 3: Cuirass CI Integration
└─ blocks on → Phase 4: Tooling & Documentation

Phase 2 blocks on Phase 1
Phase 3 blocks on Phase 2
```

---

## Key Technical Requirements

### Storage Layout (UEFI)
- **Partition 1**: EFI System Partition (512 MB, FAT32, label "EFI", mount /boot/efi, flags: esp)
- **Partition 2**: Root partition (remaining space, ext4, label "guix-root", mount /)

### Kernel Requirements
- ENA (Elastic Network Adapter) driver
- NVMe drivers for EBS volumes
- Xen drivers (legacy instances)
- KVM/virtio drivers (Nitro instances)

### Boot Configuration
- GRUB bootloader with UEFI support
- Serial console output: `console=ttyS0,115200n8`
- Timeout: 1 second
- Root device by UUID or label (not /dev/xxx)

### EC2 Integration
- DHCP network configuration
- EC2 metadata service at 169.254.169.254
- SSH key injection from metadata
- IMDSv2 token-based authentication support

### Image Format
- Raw disk image
- GPT partition table (recommended) or MBR (legacy)
- Import via AWS VM Import/Export
- Boot mode: UEFI (preferred) or BIOS legacy

---

## Testing Matrix

| Instance Type | Architecture | Virtualization | Purpose |
|---------------|--------------|----------------|---------|
| t3.micro | x86_64 | Nitro (KVM) | General purpose, modern |
| t2.micro | x86_64 | Xen | Legacy compatibility |
| t4g.micro | ARM64 | Nitro (KVM) | Graviton processors |
| m5.large | x86_64 | Nitro (KVM) | ENA driver testing |

---

## Success Criteria

1. ✅ Images boot successfully on EC2 instances
2. ✅ DHCP configuration works, metadata service accessible
3. ✅ EC2 key pairs work for SSH authentication
4. ✅ Serial console output visible in AWS Console
5. ✅ `guix pull` and `guix system reconfigure` work correctly
6. ✅ Compatible across different instance types and generations
7. ✅ Both x86_64 and ARM64 supported
8. ✅ Automated builds via cuirass
9. ✅ Clear documentation for users
10. ✅ Positive user feedback and adoption

---

## Next Steps

To recreate this project structure in beads on your local machine where SQLite works properly:

```bash
# Initialize beads
bd init

# Create all epics and tasks using the commands from the creation log
# (Or manually create them based on this document)

# View ready work
bd ready

# Get started
bd update <first-task-id> --status in_progress
```

---

## Notes

- Beads database experienced SQLite locking issues in the container environment
- All task definitions were successfully created but could not be exported to JSONL due to file system limitations
- This document serves as the authoritative project plan
- For detailed implementation guidance, refer to the comprehensive Amazon AMI implementation plan created earlier in this session
