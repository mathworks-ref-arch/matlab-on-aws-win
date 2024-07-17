# Copyright 2024 The MathWorks, Inc.

// Use this Packer configuration file to build AMI with R2023b MATLAB installed.
// For more information on these variables, see /packer/build-matlab-ami.pkr.hcl.
RELEASE  = "R2023b"
// Microsoft Windows Server 2022 Base (64-bit (x86))
BASE_AMI = "ami-0f9c44e98edf38a2b"
STARTUP_SCRIPTS = [
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
RUNTIME_SCRIPTS = [
  "Install-NVIDIAGridDriver.ps1",
  "Start-MATLABProxy.ps1",
  "generate-certificate.py"
]
BUILD_SCRIPTS = [
  "Install-StartupScripts.ps1",
  "Install-NVIDIADrivers.ps1",
  "Install-Dependencies.ps1",
  "Install-MATLABProxy.ps1",
  "Install-MATLAB.ps1",
  "Remove-IE.ps1"
]
PRODUCTS                    = "5G_Toolbox AUTOSAR_Blockset Aerospace_Blockset Aerospace_Toolbox Antenna_Toolbox Audio_Toolbox Automated_Driving_Toolbox Bioinformatics_Toolbox Bluetooth_Toolbox C2000_Microcontroller_Blockset Communications_Toolbox Computer_Vision_Toolbox Control_System_Toolbox Curve_Fitting_Toolbox DDS_Blockset DSP_HDL_Toolbox DSP_System_Toolbox Data_Acquisition_Toolbox Database_Toolbox Datafeed_Toolbox Deep_Learning_HDL_Toolbox Deep_Learning_Toolbox Econometrics_Toolbox Embedded_Coder Filter_Design_HDL_Coder Financial_Instruments_Toolbox Financial_Toolbox Fixed-Point_Designer Fuzzy_Logic_Toolbox GPU_Coder Global_Optimization_Toolbox HDL_Coder HDL_Verifier Image_Acquisition_Toolbox Image_Processing_Toolbox Industrial_Communication_Toolbox Instrument_Control_Toolbox LTE_Toolbox Lidar_Toolbox MATLAB MATLAB_Coder MATLAB_Compiler MATLAB_Compiler_SDK MATLAB_Production_Server MATLAB_Report_Generator MATLAB_Test MATLAB_Web_App_Server Mapping_Toolbox Medical_Imaging_Toolbox Mixed-Signal_Blockset Model_Predictive_Control_Toolbox Model-Based_Calibration_Toolbox Motor_Control_Blockset Navigation_Toolbox Optimization_Toolbox Parallel_Computing_Toolbox Partial_Differential_Equation_Toolbox Phased_Array_System_Toolbox Powertrain_Blockset Predictive_Maintenance_Toolbox RF_Blockset RF_PCB_Toolbox RF_Toolbox ROS_Toolbox Radar_Toolbox Reinforcement_Learning_Toolbox Requirements_Toolbox Risk_Management_Toolbox Robotics_System_Toolbox Robust_Control_Toolbox Satellite_Communications_Toolbox Sensor_Fusion_and_Tracking_Toolbox SerDes_Toolbox Signal_Integrity_Toolbox Signal_Processing_Toolbox SimBiology SimEvents Simscape Simscape_Battery Simscape_Driveline Simscape_Electrical Simscape_Fluids Simscape_Multibody Simulink Simulink_3D_Animation Simulink_Check Simulink_Coder Simulink_Compiler Simulink_Control_Design Simulink_Coverage Simulink_Design_Optimization Simulink_Design_Verifier Simulink_Desktop_Real-Time Simulink_Fault_Analyzer Simulink_PLC_Coder Simulink_Real-Time Simulink_Report_Generator Simulink_Test SoC_Blockset Spreadsheet_Link Stateflow Statistics_and_Machine_Learning_Toolbox Symbolic_Math_Toolbox System_Composer System_Identification_Toolbox Text_Analytics_Toolbox UAV_Toolbox Vehicle_Dynamics_Blockset Vehicle_Network_Toolbox Vision_HDL_Toolbox WLAN_Toolbox Wavelet_Toolbox Wireless_HDL_Toolbox Wireless_Testbench"
DCV_INSTALLER_URL           = "https://d1uj6qtbmh3dt5.cloudfront.net/2023.0/Servers/nice-dcv-server-x64-Release-2023.0-15487.msi"
NVIDIA_DRIVER_INSTALLER_URL = "https://uk.download.nvidia.com/tesla/518.03/518.03-data-center-tesla-desktop-winserver-2016-2019-2022-dch-international.exe"
PYTHON_INSTALLER_URL        = "https://www.python.org/ftp/python/3.10.5/python-3.10.5-amd64.exe"
MATLAB_PROXY_VERSION        = "0.10.0"
