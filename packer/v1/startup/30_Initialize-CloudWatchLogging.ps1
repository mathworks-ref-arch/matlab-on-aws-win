<#
.SYNOPSIS
    Enables CloudWatch logging for different applications.

.DESCRIPTION
    Configures the CloudWatch logging agent on the machine to push application logs from various locations to a specific log group.
    Different log files or application logs are set up to be pushed to different log streams, facilitating easier identification of related logs.

.PARAMETER CloudWatchLogGroupName
    (Optional) The name of the CloudWatch log group to which the application logs are pushed.

.EXAMPLE
    Initialize-CloudWatchLogging -CloudWatchLogGroupName "<NAME_OF_CLOUDWATCH_LOG_GROUP>"

.Link
    https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file.html

.NOTES
    Copyright 2023 The MathWorks Inc.
#>

function Initialize-CloudWatchLogging {

    param(
        [Parameter(Mandatory = $false)]
        [string] $CloudWatchLogGroupName

    )

    Write-Output 'Starting Initialize-CloudWatchLogging...'

    $ConfigPath = "$Env:ProgramFiles\Amazon\AmazonCloudWatchAgent\config.json"

    $WindowsVersion = (Get-ComputerInfo).OsName
    if ($WindowsVersion -eq 'Microsoft Windows Server 2019 Datacenter') {
        $UserDataExecutionLogPath = "$($Env:ProgramData.Replace('\','/'))/Amazon/EC2-Windows/Launch/Log/UserDataExecution.log"
    }
    elseif ($WindowsVersion -eq 'Microsoft Windows Server 2022 Datacenter') {
        $UserDataExecutionLogPath = "$($Env:ProgramData.Replace('\','/'))/Amazon/EC2Launch/log/agent.log"
    }
    else {
        throw "Unsupported platform: $WindowsVersion"
    }

    if ($CloudWatchLogGroupName -and -not (Test-Path $ConfigPath)) {

        $ConfigContent = @"
{
    "agent": {
        "metrics_collection_interval": 60
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "$($Env:TMP.Replace('\','/'))/mathworks_*.log",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "matlab_installation"
                    },
                    {
                        "file_path": "$($Env:TMP.Replace('\','/'))/aws_*.log",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "matlab_activation"
                    },
                    {
                        "file_path": "$($Env:TMP.Replace('\','/'))/matlab_crash_dump*",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "matlab_crashes"
                    },
                    {
                        "file_path": "$($Env:ProgramData.Replace('\','/'))/NICE/dcv/log/server.*log*",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "dcv_server"
                    },
                    {
                        "file_path": "$($Env:ProgramData.Replace('\','/'))/NICE/dcv/log/agentsession.*log*",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "dcv_sessionlauncher"
                    },
                    {
                        "file_path": "$($Env:ProgramData.Replace('\','/'))/NICE/dcv/log/agent.*log*",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "dcv_agent"
                    },
                    {
                        "file_path": "$UserDataExecutionLogPath",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "user_data_execution"
                    },
                    {
                        "file_path": "$($Env:ProgramData.Replace('\','/'))/MathWorks/startup.log",
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "startup"
                    }
                ]
            },
            "windows_events": {
                "collect_list": [
                    {
                        "event_name": "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational",
                        "event_levels": [
                            "INFORMATION",
                            "WARNING",
                            "ERROR",
                            "CRITICAL"
                        ],
                        "log_group_name": "$($CloudWatchLogGroupName)",
                        "log_stream_name": "windows_rdp_events"
                    }
                ]
            }
        }
    }
}
"@

        Set-Content -Path $ConfigPath -Value $ConfigContent

        # In this command:
        #     -a fetch-config causes the agent to load the latest version of the CloudWatch agent configuration file;
        #     -m tells the agent the host is on ec2;
        #     -s starts the agent;
        #     -c points to the configuration file
        & "$Env:ProgramFiles\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c file:$ConfigPath

    }

    Write-Output 'Done with Initialize-CloudWatchLogging.'
}



try {
    Initialize-CloudWatchLogging -CloudWatchLogGroupName $Env:CloudLogName
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Initialize-CloudWatchLogging': $ScriptPath. Error: $_"
    throw
}
