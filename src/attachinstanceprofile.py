# Copyright 2023-2025 The MathWorks, Inc.
import http, json, os, uuid, boto3
from urllib.parse import urlparse
from botocore.waiter import WaiterModel as Waiter, create_waiter_with_client as create_waiter

INSTANCE_ID=os.environ['EC2_INSTANCE_ID']
PROFILE_ID=os.environ['INSTANCE_PROFILE_ID']
REGION=os.environ['AWS_REGION']

def get_waiter_cfg(operation,argument,retry_error_codes):
    acceptors = [{"matcher":"path","expected":True,"argument":argument,"state":"success"}] + [{"matcher":"error","expected":error_code,"state":"retry","argument":"Code"} for error_code in retry_error_codes]
    cfg={"version":2,"waiters":{"CustomWaiter":{"delay":3,"operation":operation,"maxAttempts":100,"acceptors": acceptors}}}
    return cfg

def get_resources(stack,response):
    cfn=boto3.client('cloudformation')
    res={}
    waiter_cfg=get_waiter_cfg("DescribeStackResource","StackResourceDetail.ResourceStatus==`CREATE_IN_PROGRESS` || StackResourceDetail.ResourceStatus==`CREATE_COMPLETE`",["ValidationError"])
    waiter=create_waiter('CustomWaiter', Waiter(waiter_cfg), cfn)
    for id in [INSTANCE_ID, PROFILE_ID]:
        try:
            waiter.wait(StackName=stack,LogicalResourceId=id)
            resource=cfn.describe_stack_resource(StackName=stack,LogicalResourceId=id)
            res[id]=resource['StackResourceDetail']['PhysicalResourceId']
        except Exception as e:
            print(e)
            response['Reason']=f"Error retrieving resource: {str(e)}."
    return res

def send_response(request,response):
    url=urlparse(request['ResponseURL'])
    body=json.dumps(response)
    https=http.client.HTTPSConnection(url.netloc)
    https.request('PUT', url.path+'?'+url.query,body)
    return response
 
def lambda_handler(event,context): 
    response={'StackId':event['StackId'],'RequestId':event['RequestId'],'LogicalResourceId':event['LogicalResourceId'],'Status':'SUCCESS'}
    stack=str(event['StackId']).split('/')[1]
    if 'PhysicalResourceId' in event:
        response['PhysicalResourceId']=event['PhysicalResourceId']
    else:
        response['PhysicalResourceId']=str(uuid.uuid4())
    if event['RequestType'] == 'Delete':
        return send_response(event,response)
    try:
        ec2=boto3.client('ec2')
        resources=get_resources(stack,response)
        waiter_cfg=get_waiter_cfg("AssociateIamInstanceProfile","IamInstanceProfileAssociation.State==`associated` || IamInstanceProfileAssociation.State==`associating`",["InvalidParameterValue","IncorrectInstanceState"])
        waiter=create_waiter('CustomWaiter', Waiter(waiter_cfg), ec2)
        waiter.wait(IamInstanceProfile={'Name':resources[PROFILE_ID]},InstanceId=resources[INSTANCE_ID])
        response['Reason']='Attached instance profile successfully'
        print(response['Reason'])
    except Exception as e:
        print(e)
        response['Status']='FAILED'
        if 'Reason' not in response:
           response['Reason']=f"Error attaching instance profile: {str(e)}."
    return send_response(event,response)