# Copyright 2026 The MathWorks, Inc.

"""
Shared helpers for the end-to-end test suite.
"""

import logging

from botocore.exceptions import WaiterError

logger = logging.getLogger(__name__)


def run_ssm_powershell(ssm_client, instance_id, script, max_attempts=30, delay=5):
    """
    Run a PowerShell script on an instance via SSM Run Command and wait for it.

    Returns the ``get_command_invocation`` response.
    """
    response = ssm_client.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunPowerShellScript",
        Parameters={"commands": script.strip().splitlines()},
    )
    command_id = response["Command"]["CommandId"]

    waiter = ssm_client.get_waiter("command_executed")
    try:
        waiter.wait(
            CommandId=command_id,
            InstanceId=instance_id,
            WaiterConfig={"Delay": delay, "MaxAttempts": max_attempts},
        )
    except WaiterError as e:
        # A failed command also surfaces as a waiter failure; the invocation has the detail.
        logger.warning(f"SSM command did not complete cleanly: {e}")

    return ssm_client.get_command_invocation(
        CommandId=command_id,
        InstanceId=instance_id,
    )


def run_ssm_powershell_checked(ssm_client, instance_id, script, **kwargs):
    """Run a PowerShell script via SSM and return stdout, failing on error."""
    output = run_ssm_powershell(ssm_client, instance_id, script, **kwargs)
    if output["Status"] != "Success":
        raise AssertionError(
            f"SSM command failed with status {output['Status']}: "
            f"{output.get('StandardErrorContent', '').strip()}"
        )
    return output.get("StandardOutputContent", "")
