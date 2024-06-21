# Copyright 2024 The MathWorks Inc.

variable "RELEASE" {
  type        = string
  default     = "R2024a"
  description = "Target MATLAB release to install in the machine image, must start with \"R\"."

  validation {
    condition     = can(regex("^R20[0-9][0-9](a|b)(U[0-9])?$", var.RELEASE))
    error_message = "The RELEASE value must be a valid MATLAB release, starting with \"R\"."
  }
}

variable "PRODUCTS" {
  type        = string
  default     = "5G_Toolbox AUTOSAR_Blockset Aerospace_Blockset Aerospace_Toolbox Antenna_Toolbox Audio_Toolbox Automated_Driving_Toolbox Bioinformatics_Toolbox Bluetooth_Toolbox C2000_Microcontroller_Blockset Communications_Toolbox Computer_Vision_Toolbox Control_System_Toolbox Curve_Fitting_Toolbox DDS_Blockset DSP_HDL_Toolbox DSP_System_Toolbox Data_Acquisition_Toolbox Database_Toolbox Datafeed_Toolbox Deep_Learning_HDL_Toolbox Deep_Learning_Toolbox Econometrics_Toolbox Embedded_Coder Filter_Design_HDL_Coder Financial_Instruments_Toolbox Financial_Toolbox Fixed-Point_Designer Fuzzy_Logic_Toolbox GPU_Coder Global_Optimization_Toolbox HDL_Coder HDL_Verifier Image_Acquisition_Toolbox Image_Processing_Toolbox Industrial_Communication_Toolbox Instrument_Control_Toolbox LTE_Toolbox Lidar_Toolbox MATLAB MATLAB_Coder MATLAB_Compiler MATLAB_Compiler_SDK MATLAB_Production_Server MATLAB_Report_Generator MATLAB_Test MATLAB_Web_App_Server Mapping_Toolbox Medical_Imaging_Toolbox Mixed-Signal_Blockset Model_Predictive_Control_Toolbox Model-Based_Calibration_Toolbox Motor_Control_Blockset Navigation_Toolbox Optimization_Toolbox Parallel_Computing_Toolbox Partial_Differential_Equation_Toolbox Phased_Array_System_Toolbox Powertrain_Blockset Predictive_Maintenance_Toolbox RF_Blockset RF_PCB_Toolbox RF_Toolbox ROS_Toolbox Radar_Toolbox Reinforcement_Learning_Toolbox Requirements_Toolbox Risk_Management_Toolbox Robotics_System_Toolbox Robust_Control_Toolbox Satellite_Communications_Toolbox Sensor_Fusion_and_Tracking_Toolbox SerDes_Toolbox Signal_Integrity_Toolbox Signal_Processing_Toolbox SimBiology SimEvents Simscape Simscape_Battery Simscape_Driveline Simscape_Electrical Simscape_Fluids Simscape_Multibody Simulink Simulink_3D_Animation Simulink_Check Simulink_Coder Simulink_Compiler Simulink_Control_Design Simulink_Coverage Simulink_Design_Optimization Simulink_Design_Verifier Simulink_Desktop_Real-Time Simulink_Fault_Analyzer Simulink_PLC_Coder Simulink_Real-Time Simulink_Report_Generator Simulink_Test SoC_Blockset Spreadsheet_Link Stateflow Statistics_and_Machine_Learning_Toolbox Symbolic_Math_Toolbox System_Composer System_Identification_Toolbox Text_Analytics_Toolbox UAV_Toolbox Vehicle_Dynamics_Blockset Vehicle_Network_Toolbox Vision_HDL_Toolbox WLAN_Toolbox Wavelet_Toolbox Wireless_HDL_Toolbox Wireless_Testbench"
  description = "Target products to install in the machine image, e.g. MATLAB SIMULINK."

}

variable "BASE_AMI" {
  type        = string
  default     = "ami-0f9c44e98edf38a2b"
  description = "Default AMI ID refers to the Windows Server 2022 image provided by Microsoft."

  validation {
    condition     = can(regex("^ami-", var.BASE_AMI))
    error_message = "The BASE_AMI must start with \"ami-\"."
  }
}

variable "BUILD_SCRIPTS" {
  type = list(string)
  default = [
    "Install-StartupScripts.ps1",
    "Install-NVIDIADrivers.ps1",
    "Install-Dependencies.ps1",
    "Install-MATLABProxy.ps1",
    "Install-MATLAB.ps1",
    "Remove-IE.ps1"
  ]
  description = "The list of installation scripts Packer will use when building the image."
}

variable "STARTUP_SCRIPTS" {
  type = list(string)
  default = [
    "env.ps1",
    "00_Confirm-InstanceProfile.ps1",
    "10_Initialize-EBSVolume.ps1",
    "20_Set-AdminPassword.ps1",
    "30_Initialize-CloudWatchLogging.ps1",
    "40_Set-DDUX.ps1",
    "50_Setup-MATLABProxy.ps1",
    "60_Set-MATLABLicense.ps1",
    "70_Invoke-MATLABStartupAccelerator.ps1",
    "80_Invoke-MSHStartupAccelerator.ps1",
    "99_Invoke-OptionalUserCommand.ps1"
  ]
  description = "The list of startup scripts Packer will copy to the remote machine image builder, which can be used during the CloudFormation Stack creation."
}

variable "RUNTIME_SCRIPTS" {
  type = list(string)
  default = [
    "Install-NVIDIAGridDriver.ps1",
    "Start-MATLABProxy.ps1",
    "generate-certificate.py"
  ]
  description = "The list of runtime scripts Packer will copy to the remote machine image builder, which can be used after the CloudFormation Stack creation."
}

variable "DCV_INSTALLER_URL" {
  type        = string
  default     = "https://d1uj6qtbmh3dt5.cloudfront.net/2023.0/Servers/nice-dcv-server-x64-Release-2023.0-15487.msi"
  description = "The URL to install NICE DCV, a remote display protocol to use."
}

variable "NVIDIA_DRIVER_INSTALLER_URL" {
  type        = string
  default     = "https://us.download.nvidia.com/tesla/538.15/538.15-data-center-tesla-desktop-winserver-2019-2022-dch-international.exe"
  description = "The URL to install NVIDIA drivers into the target machine image."
}

variable "PYTHON_INSTALLER_URL" {
  type        = string
  default     = "https://www.python.org/ftp/python/3.10.5/python-3.10.5-amd64.exe"
  description = "The URL to install python into the target machine image."
}

variable "MATLAB_SOURCE_URL" {
  type        = string
  default     = ""
  description = "Optional URL from which to download a MATLAB and toolbox source file, for use with the mpm --source option."
}

# The following variables share the same setup across all MATLAB releases.
variable "VPC_ID" {
  type        = string
  default     = ""
  description = "The target AWS VPC to be used by Packer. If not specified, Packer will use default VPC."

  validation {
    condition     = length(var.VPC_ID) == 0 || substr(var.VPC_ID, 0, 4) == "vpc-"
    error_message = "The VPC_ID must start with \"vpc-\"."
  }
}

variable "SUBNET_ID" {
  type        = string
  default     = ""
  description = "The target subnet to be used by Packer. If not specified, Packer will use the subnet that has the most free IP addresses."

  validation {
    condition     = length(var.SUBNET_ID) == 0 || substr(var.SUBNET_ID, 0, 7) == "subnet-"
    error_message = "The SUBNET_ID must start with \"subnet-\"."
  }
}

variable "INSTANCE_TAGS" {
  type = map(string)
  default = {
    Name  = "Packer Builder"
    Build = "MATLAB"
  }
  description = "The tags Packer adds to the machine image builder."
}

variable "AMI_TAGS" {
  type = map(string)
  default = {
    Name     = "Packer Build"
    Build    = "MATLAB"
    Type     = "matlab-on-aws"
    Platform = "Windows"
  }
  description = "The tags Packer adds to the resultant machine image."
}

variable "MANIFEST_OUTPUT_FILE" {
  type        = string
  default     = "packer_manifest.json"
  description = "The name of the resultant manifest file."
}

variable "PACKER_ADMIN_USERNAME" {
  type        = string
  default     = "Administrator"
  description = "Username for the build instance."
}

variable "PACKER_ADMIN_PASSWORD" {
  type        = string
  description = "Password for the build instance. Must be provided as a build argument. Must satisfy password complexity requirements of base operating system."
  sensitive = true
  validation {
    condition     = length(var.PACKER_ADMIN_PASSWORD) > 11
    error_message = "Password must be at least 12 characters long."
  }
}

variable "AWS_INSTANCE_PROFILE" {
  type        = string
  default     = ""
  description = "The AWS instance profile role used during Packer builds."
}

variable "MATLAB_PROXY_VERSION" {
  type        = string
  default     = "0.10.0"
  description = "The matlab-proxy version to use."
}

# Set up local variables used by provisioners.
locals {
  timestamp             = regex_replace(timestamp(), "[- TZ:]", "")
  build_scripts         = [for s in var.BUILD_SCRIPTS : format("build/%s", s)]
  startup_scripts       = [for s in var.STARTUP_SCRIPTS : format("startup/%s", s)]
  runtime_scripts       = [for s in var.RUNTIME_SCRIPTS : format("runtime/%s", s)]
  packer_admin_username = "${var.PACKER_ADMIN_USERNAME}"
  packer_admin_password = "${var.PACKER_ADMIN_PASSWORD}"
}

# Configure the EC2 instance that is used to build the machine image.
source "amazon-ebs" "AMI_Builder" {
  ami_name = "CustomPacker-matlab-${var.RELEASE}-${local.timestamp}"
  aws_polling {
    delay_seconds = 60
    max_attempts  = 240
  }
  communicator  = "winrm"
  instance_type = "g4dn.xlarge"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 128
    volume_type           = "gp2"
  }
  region                                    = "us-east-1"
  source_ami                                = "${var.BASE_AMI}"
  subnet_id                                 = "${var.SUBNET_ID}"
  run_tags                                  = "${var.INSTANCE_TAGS}"
  tags                                      = "${var.AMI_TAGS}"
  temporary_security_group_source_public_ip = true
  user_data                                 = templatefile("./build/config/packer/bootstrap_win.pkrtpl.hcl", { winrm_username = local.packer_admin_username, winrm_password = local.packer_admin_password })
  vpc_id                                    = "${var.VPC_ID}"
  winrm_username                            = "${local.packer_admin_username}"
  winrm_password                            = "${local.packer_admin_password}"
  iam_instance_profile                      = "${var.AWS_INSTANCE_PROFILE}"

  # The `Get-NVidiaGridDrivers` function involves retrieving files from an AWS-owned S3 bucket, which needs S3 permissions for the packer EC2.
  # If you are adding/updating scripts that require AWS permissions from inside the Packer EC2 instance, you can add those permissions here.
  temporary_iam_instance_profile_policy_document {
    Version = "2012-10-17"
    Statement {
      Effect = "Allow"
      Action = [
        "s3:Get*",
        "s3:List*",
        "s3:Describe*",
        "s3-object-lambda:Get*",
        "s3-object-lambda:List*"
      ]
      Resource = ["*"]
    }
  }

}

build {
  sources = ["source.amazon-ebs.AMI_Builder"]

  provisioner "file" {
    destination = "C:/Windows/Temp/"
    source      = "build/config"
  }

  provisioner "file" {
    destination = "C:/Windows/Temp/startup/"
    sources     = "${local.startup_scripts}"
  }

  provisioner "file" {
    destination = "C:/Windows/Temp/runtime/"
    sources     = "${local.runtime_scripts}"
  }

  provisioner "powershell" {
    elevated_user     = "${local.packer_admin_username}"
    elevated_password = "${local.packer_admin_password}"
    scripts           = ["build/Enable-OpenSSh.ps1"]
  }

  provisioner "powershell" {
    environment_vars = [
      "RELEASE=${var.RELEASE}",
      "PRODUCTS=${var.PRODUCTS}",
      "NVIDIA_DRIVER_INSTALLER_URL=${var.NVIDIA_DRIVER_INSTALLER_URL}",
      "DCV_INSTALLER_URL=${var.DCV_INSTALLER_URL}",
      "PYTHON_INSTALLER_URL=${var.PYTHON_INSTALLER_URL}",
      "MATLAB_SOURCE_URL=${var.MATLAB_SOURCE_URL}",
      "MATLAB_PROXY_VERSION=${var.MATLAB_PROXY_VERSION}"
    ]
    scripts = "${local.build_scripts}"
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'System restarted.'}\""
  }

  provisioner "powershell" {
    scripts = [
      "build/Remove-TemporaryFiles.ps1",
      "build/Invoke-Sysprep.ps1"
      ]
  }

  post-processor "manifest" {
    output     = "${var.MANIFEST_OUTPUT_FILE}"
    strip_path = true
    custom_data = {
      release            = "MATLAB ${var.RELEASE}"
      specified_products = "${var.PRODUCTS}"
      build_scripts      = join(", ", "${var.BUILD_SCRIPTS}")
    }
  }
}
