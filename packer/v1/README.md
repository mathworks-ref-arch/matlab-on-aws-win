# **Build Your Own Machine Image**

## **Introduction**
This guide shows how to build your own Amazon® Machine Image (AMI) using the same scripts that form the basis of the build process for MathWorks® prebuilt images.
You can use the scripts to install MATLAB®, MATLAB toolboxes, and the other features detailed below.

A HashiCorp® Packer template generates the machine image.
The template is an HCL2 file that tells Packer which plugins (builders, provisioners, post-processors) to use, how to configure each of those plugins, and what order to run them in.
For more information about templates, see [Packer Templates](https://developer.hashicorp.com/packer/docs/templates#packer-templates).

When you launch a MATLAB instance from your custom image, you might experience a delay in startup speed compared to the prebuilt images. The prebuilt images have additional configurations to enhance startup times.



## **Requirements**
Before starting, you will need:
* A valid Packer installation later than 1.7.0. For more information, see [Install Packer](https://developer.hashicorp.com/packer/install).
* Amazon Web Services (AWS&reg;) credentials with sufficient permission. For more information, see [Packer Authentication](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#authentication).

## **Costs**
You are responsible for the cost of the AWS services used when you create cloud resources using this guide. Resource settings, such as instance type, will affect the cost of deployment. For cost estimates, see the pricing pages for each AWS service you will be using. Prices are subject to change.

## **Quick Launch Instructions**
This section shows how to build the latest MATLAB machine image in your own AWS account. 

Pull the source code and navigate to the Packer folder.
```bash
git clone https://github.com/mathworks-ref-arch/matlab-on-aws-win.git
cd matlab-on-aws-win\\packer\\v1
```

Initialize Packer to install the required plugins.
You only need to do this once.
For more information, see [init command reference (Packer)](https://developer.hashicorp.com/packer/docs/commands/init).
```bash
packer init build-matlab-ami.pkr.hcl
```

Launch the Packer build with the default settings.
Set the `PACKER_ADMIN_PASSWORD` as a command line parameter.
```bash
packer build -var="PACKER_ADMIN_PASSWORD=<password>" build-matlab-ami.pkr.hcl
```
Packer writes its output, including the ID of the generated machine image, to a `packer_manifest.json` file at the end of the build.
To use the built image with a MathWorks CloudFormation template, see [Deploy Machine Image](#deploy-machine-image).


## **How to Run the Packer Build**
This section describes the complete Packer build process and the different options for launching the build.


### **Build-Time Variables**
The [Packer template](https://github.com/mathworks-ref-arch/matlab-on-aws-win/tree/master/packer/v1/build-matlab-ami.pkr.hcl)
supports these build-time variables.
| Argument Name | Default Value | Description |
|---|---|---|
| [PRODUCTS](#customize-products-to-install)| MATLAB and all available toolboxes | Products to install, specified as a list of product names separated by spaces. For example, `MATLAB Simulink Deep_Learning_Toolbox Parallel_Computing_Toolbox`.<br/>If no products are specified, the Packer build will install MATLAB with all available toolboxes. For more information, see [MATLAB Package Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md).|
| PACKER_ADMIN_PASSWORD | *unset*, must be set as a build argument. | Password used by Packer to connect to the build instance. Must be at least 12 characters long, and be a combination of uppercase letters, lowercase letters, numbers, and symbols. |
| BASE_AMI | Default AMI ID refers to Windows_Server-2022-English-Full-Base. | The base AMI upon which the image is built, defaults to the Windows Server 2022 image provided by Microsoft. |
| VPC_ID | *unset* | VPC to assign to the Packer build instance. If no VPC is specified, the default VPC will be used.|
| SUBNET_ID | *unset* | Subnet to assign to the Packer build instance. If no subnet is specified, the subnet with the most free IPv4 addresses will be used.|
| INSTANCE_TAGS |{Name="Packer Builder", Build="MATLAB"} | Tags to add to the Packer build instance.|
| AMI_TAGS | {Name="Packer Build", Build="MATLAB", Type="matlab-on-aws", Platform = "Windows"} | Tags to add to the machine image.|

For a full list of the variables used in the build, see the description fields in the
[Packer template](https://github.com/mathworks-ref-arch/matlab-on-aws-win/tree/master/packer/v1/build-matlab-ami.pkr.hcl).



### **Customize Packer Build**
#### **Customize Products to Install**
Use the Packer build-time variable `PRODUCTS` to specify the list of products you want to install on the machine image. If unspecified, Packer will install MATLAB with all the available toolboxes.

For example, install the latest version of MATLAB and Deep Learning Toolbox&trade;.
```bash
packer build -var="PRODUCTS=MATLAB Deep_Learning_Toolbox" -var="PACKER_ADMIN_PASSWORD=<password>" build-matlab-ami.pkr.hcl
```

#### **Customize MATLAB Release to Install**
To use an earlier MATLAB release, you must use one of the variable definition files in the [release-config](https://github.com/mathworks-ref-arch/matlab-on-aws-win/tree/master/packer/v1/release-config) folder.
These are available for MATLAB R2020b and later.

For example, install MATLAB R2020b and all available toolboxes.
```bash
packer build -var-file="release-config\R2020b.pkrvars.hcl" -var="PACKER_ADMIN_PASSWORD=<password>" build-matlab-ami.pkr.hcl
```
Command line arguments can also be combined. For example, install MATLAB R2020b and the Parallel Computing Toolbox&trade; only.
```bash
packer build -var-file="release-config\R2020b.pkrvars.hcl" -var="PRODUCTS=MATLAB Parallel_Computing_Toolbox" -var="PACKER_ADMIN_PASSWORD=<password>" build-matlab-ami.pkr.hcl
```
Launch the customized image using the corresponding CloudFormation Template.
For instructions on how to use CloudFormation Templates, see the Deployment Steps
section on [MATLAB on Amazon Web Services](https://github.com/mathworks-ref-arch/matlab-on-aws-win).
#### **Customize Multiple Variables**
You can set multiple variables in a [Variable Definition File](https://developer.hashicorp.com/packer/docs/templates/hcl_templates/variables#standard-variable-definitions-files).

For example, to generate a machine image with the most recent MATLAB installed with additional toolboxes in a custom VPC, create a variable definition file named `custom-variables.pkrvars.hcl` containing these variable definitions.
```
VPC_ID    = <any_VPC_id>
PRODUCTS  = "MATLAB Deep_Learning_Toolbox Parallel_Computing_Toolbox"
```

To specify a MATLAB release using a variable definition file, modify the variable definition file
in the [release-config](https://github.com/mathworks-ref-arch/matlab-on-aws-win/tree/master/packer/v1/release-config)
folder corresponding to the desired release.

Save the variable definition file and include it in the Packer build command.
```bash
packer build -var-file="custom-variables.pkrvars.hcl" -var="PACKER_ADMIN_PASSWORD=<password>" build-matlab-ami.pkr.hcl
```

### **Installation Scripts**
The Packer build executes scripts on the image builder instance during the build.
These scripts perform tasks such as
installing tools needed by the build,
installing MATLAB and toolboxes on the image using [MATLAB Package Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md),
and cleaning up temporary files used by the build.

For the full list of scripts that the Packer build executes during the build, see the `BUILD_SCRIPTS` parameter in the
[Packer template](https://github.com/mathworks-ref-arch/matlab-on-aws-win/tree/master/packer/v1/build-matlab-ami.pkr.hcl).
The prebuilt images that MathWorks provides are built using these scripts as a base, and additionally have support packages installed.

In addition to the build scripts above, the Packer build copies further scripts to the machine image,
to be used during startup and at runtime. These scripts perform tasks such as
mounting available storage and
initializing CloudWatch logging (if this is chosen),
among other utility tasks.

For the full list of startup and runtime scripts, see the `STARTUP_SCRIPTS` and the `RUNTIME_SCRIPTS` parameters in the
[Packer template](https://github.com/mathworks-ref-arch/matlab-on-aws-win/tree/master/packer/v1/build-matlab-ami.pkr.hcl).


## Validate Packer Template
To validate the syntax and configuration of a Packer template, use the `packer validate` command. This command also checks whether the provided input variables meet the custom validation rules defined by MathWorks. For more information, see [validate Command](https://developer.hashicorp.com/packer/docs/commands/validate#validate-command).

You can also use command line interfaces provided by Packer to inspect and format the template. For more information, see [Packer Commands (CLI)](https://developer.hashicorp.com/packer/docs/commands).

## Deploy Machine Image
When the build finishes, Packer writes
the output to a `packer_manifest.json` file, which contains these fields:
```json
{
  "builds": [
    {
      "name":,
      "builder_type": ,
      "build_time": ,
      "files": ,
      "artifact_id": ,
      "packer_run_uuid": ,
      "custom_data": {
        "build_scripts": ,
        "release": ,
        "specified_products":
      }
    }
  ],
  "last_run_uuid": ""
}
```

The `artifact_id` section shows the ID of the machine image generated by the most recent Packer build.

The CloudFormation templates provided by MathWorks for releases R2024a onwards include an optional custom machine image ID field, `CustomAmiId`.
If you do not specify a custom machine image ID, the template
launches a prebuilt image provided by MathWorks. To launch a custom machine image,
provide the `artifact_id` from the `packer_manifest.json` file as the `CustomAmiId`.

For AMIs built with an earlier MATLAB release, replace the AMI ID in the
corresponding CloudFormation template with the AMI ID of your customized image.

If the build has been customized, for example by removing or modifying one or more of the included scripts,
the resultant machine image **may no longer be compatible** with the provided CloudFormation template.
Compatibility can in some cases be restored by making corresponding modifications to the CloudFormation template.

## Help Make MATLAB Even Better
You can help improve MATLAB by providing user experience information on how you use MathWorks products. Your participation ensures that you are represented and helps us design better products.
To opt out of this service, remove the [40_Set-DDUX.ps1](https://github.com/mathworks-ref-arch/matlab-on-aws-win/tree/master/packer/v1/startup/40_Set-DDUX.ps1)
script under the `startup` folder.

To learn more, see the documentation: [Help Make MATLAB Even Better - Frequently Asked Questions](https://www.mathworks.com/support/faq/user_experience_information_faq.html).

## Technical Support
If you require assistance or have a request for additional features or capabilities, contact [MathWorks Technical Support](https://www.mathworks.com/support/contact_us.html).

----

Copyright 2024 The MathWorks, Inc.

----
