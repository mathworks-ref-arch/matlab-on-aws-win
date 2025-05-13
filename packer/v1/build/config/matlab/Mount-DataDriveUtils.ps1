# Copyright 2025 The MathWorks, Inc.
function Get-IMDSV2Token {
    <#
    .SYNOPSIS
    Retrieves an IMDSv2 token from the EC2 instance metadata service.

    .DESCRIPTION
    This function sends a request to the EC2 instance metadata service to obtain an IMDSv2 token.
    The token is used for subsequent requests to retrieve instance metadata.

    .PARAMETER TokenDuration
    The desired duration of the token in seconds.

    .RETURNS
    Returns the IMDSv2 token as a string.

    .EXAMPLE
    $token = Get-IMDSV2Token -TokenDuration 300
    #>
    param (
        [string]$TokenDuration
    )
    $Token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "$TokenDuration"} -Method Put -Uri "http://169.254.169.254/latest/api/token"
    return $Token
}

function Get-MATLABSourceFiles {
    <#
    .SYNOPSIS
    Downloads MATLAB source files from an S3 URL and extracts them to a specified destination.

    .PARAMETER SourceUrl
    The S3 URL of the zip file containing MATLAB source files.

    .PARAMETER Destination
    The local directory where the source files will be extracted.

    .EXAMPLE
    Get-MATLABSourceFiles -SourceUrl "s3://mybucket/matlab-source.zip" -Destination "C:\MATLABSource"
    #>
    param (
        [string]$SourceUrl,
        [string]$Destination
    )
    New-Item -Path "$Destination" -ItemType Directory -Force
    aws s3 cp "$SourceUrl" "$Destination\source.zip"
    Expand-Archive -Path "$Destination\source.zip" -DestinationPath "$Destination" -Force
    Remove-Item -Path "$Destination\source.zip"
}

function Wait-VolumeAttachment {
    <#
    .SYNOPSIS
    Waits for an EBS volume to be attached to an EC2 instance.

    .DESCRIPTION
    This function polls the AWS EC2 API to check the attachment status of a specified volume to a specified instance.
    It continues checking until the volume is attached or the timeout is reached.

    .PARAMETER VolumeId
    The ID of the EBS volume to check.

    .PARAMETER InstanceId
    The ID of the EC2 instance to which the volume should be attached.

    .PARAMETER Region
    The AWS region where the volume and instance are located.

    .PARAMETER TimeoutSeconds
    The maximum time to wait for the attachment, in seconds. Default is 300 seconds (5 minutes).

    .EXAMPLE
    Wait-VolumeAttachment -VolumeId "vol-1234567890abcdef0" -InstanceId "i-1234567890abcdef0" -Region "us-west-2"
    #>
    param (
        [string]$VolumeId,
        [string]$InstanceId,
        [string]$Region,
        [int]$TimeoutSeconds = 300
    )

    $StartTime = Get-Date
    $EndTime = $StartTime.AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $EndTime) {
        $AttachmentStatus = $(aws ec2 describe-volumes --region $Region --volume-ids $VolumeId --query "Volumes[0].Attachments[?InstanceId=='$InstanceId'].State" --output text)
        if ($AttachmentStatus -eq 'attached') {
            return
        }
        Start-Sleep -Seconds 5
    }
    throw "Failed to attach volume $VolumeID to instance $InstanceID."
}

function Mount-DataDrive {
    <#
    .SYNOPSIS
    Creates and mounts an EBS volume to an EC2 instance and assigns it a specified drive letter.

    .DESCRIPTION
    This function creates a new 128GB gp3 EBS volume in the same availability zone as the EC2 instance,
    attaches it to the instance, initializes the disk, creates a partition, formats it with NTFS,
    and assigns it the specified drive letter.

    .PARAMETER DriveToMount
    The drive letter to assign to the newly created and mounted volume.

    .EXAMPLE
    Mount-DataDrive -DriveToMount "M"
    #>
    param (
        [string]$DriveToMount
    )

    $IMDSToken = Get-IMDSV2Token -TokenDuration 300

    $InstanceID = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $IMDSToken} -Method Get -Uri "http://169.254.169.254/latest/meta-data/instance-id"
    $Region = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $IMDSToken} -Method Get -Uri "http://169.254.169.254/latest/meta-data/placement/region"
    $AvailabilityZone = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $IMDSToken} -Method Get -Uri "http://169.254.169.254/latest/meta-data/placement/availability-zone"

    $VolumeID=$(aws ec2 create-volume --size 128 --volume-type gp3 --availability-zone $AvailabilityZone --query "VolumeId" --output text)

    aws ec2 wait volume-available --region $Region --volume-ids $VolumeID
    
    aws ec2 attach-volume --region $Region --volume-id $VolumeID --instance-id $InstanceID --device xvdf

    # Wait for the volume to attach
    try {
        Wait-VolumeAttachment -VolumeId $VolumeID -InstanceId $InstanceID -Region $Region
        Write-Output "Volume $VolumeId is successfully attached to the instance $InstanceId."
    } catch {
        throw "An error occurred while waiting for the volume $VolumeID to attach to instance $InstanceID : $_"
    }

    aws ec2 modify-instance-attribute --region $Region --instance-id $InstanceID --block-device-mappings '[{\"DeviceName\":\"xvdf\",\"Ebs\":{\"DeleteOnTermination\":true}}]'

    # AWS formats the serial number of disk in the format "volXXXX"
    $FormattedVolumeID = $VolumeID.Replace("-", "")

    # Sleep for 10 seconds to make sure the mounted disk is ready
    Start-Sleep -Seconds 10

    # Find the physical disk by matching the formatted volume ID with the serial number
    $Disk = Get-PhysicalDisk | Where-Object {
        $_.SerialNumber -like "*$FormattedVolumeID*"
    }

    if ($Disk) {
        # Get the disk number
        $DiskNumber = ($Disk | Get-Disk).Number
        Stop-Service -Name ShellHWDetection
        # Initialize the disk, create a Partition, and format it
        Initialize-Disk -Number $DiskNumber -PartitionStyle MBR -PassThru |
                    New-Partition -DriveLetter "$DriveToMount" -UseMaximumSize |
                    Format-Volume -FileSystem NTFS -NewFileSystemLabel "MATLAB Source Volume" -Confirm:$false

        Start-Service -Name ShellHWDetection
    } else {
        Write-Output "No disk found with the volume ID: $FormattedVolumeID"
    }
    
}


function Dismount-DataDrive {
    <#
    .SYNOPSIS
    Dismounts and deletes an EBS volume associated with a given drive letter.

    .DESCRIPTION
    This function takes a drive letter as input, finds the corresponding EBS volume,
    detaches it from the EC2 instance, and then deletes the volume.

    .PARAMETER DriveLetter
    The drive letter of the volume to be dismounted and deleted.

    .EXAMPLE
    Dismount-DataDrive -DriveLetter "M"
    #>
    param (
        [string]$DriveLetter
    )

    # Retrieve the serial number of the disk
    $Partition = Get-Partition | Where-Object { $_.DriveLetter -eq $DriveLetter }

    # Check if there's a drive with the specified letter
    if (-not $Partition) {
        Write-Output "No drive found with the letter $DriveLetter"
        return
    }
    
    $diskNumber = $Partition.DiskNumber
    $PhysicalDisk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq $diskNumber }
    $SerialNumber = $PhysicalDisk.SerialNumber

    # AWS formats the serial number in the format "volXXXX"
    # Extract the volume ID from the serial number
    if ($SerialNumber -match "^(vol[0-9a-f]+)_") {
        $RawVolumeId = $matches[1]
        
        # Convert to AWS format by inserting a hyphen after 'vol'
        $VolumeId = $RawVolumeId.Insert(3, "-")
        
        Write-Output "The volume ID is: $VolumeId"
    } else {
        Write-Output "Failed to extract a volume ID from the serial number: $SerialNumber"
        return
    }

    # Unmount the volume
    Set-Disk -Number $diskNumber -IsOffline $true

    $IMDSToken = Get-IMDSV2Token -TokenDuration 300

    # Retrieve instance metadata using IMDSv2
    $Region = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $IMDSToken} -Method Get -Uri "http://169.254.169.254/latest/meta-data/placement/region"

    # Detach and delete the volume using AWS CLI
    try {
        aws ec2 detach-volume --volume-id $VolumeId --region $Region
        aws ec2 wait volume-available --region $Region --volume-ids $VolumeId
        aws ec2 delete-volume --region $Region --volume-id $VolumeId
        Write-Output "Successfully detached and deleted volume $VolumeId."
    } catch {
        Write-Output "Failed to detach or delete volume ${VolumeId}: $_"
    }
}
