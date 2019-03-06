# Sophos NSG CloudFormation Templates

This repository tracks the templates used within the Sophos NSG CloudFormation template S3 bucket *s3://sophos-nsg-cf/*


## Instant Deployment

With the templates we provide, you can instantly deploy our UTM solutions on AWS using any of the Amazon 1-Click launch options below.

### Sophos UTM (High Availability, Cold Standby) ###

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=sophos-utm&templateURL=https://s3.amazonaws.com/sophos-nsg-cf/utm/ha_standalone.template">
<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"/></a>

### Sophos UTM (High Availability, Warm Standby) ###

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=sophos-utm&templateURL=https://s3.amazonaws.com/sophos-nsg-cf/utm/ha_warm_standby.template">
<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"/></a>

### Sophos UTM (Auto Scaling) ###

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=sophos-utm&templateURL=https://s3.amazonaws.com/sophos-nsg-cf/utm/autoscaling.template">
<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"/></a>

## Manual Setup using the CloudFormation templates

You can use any of the templates with CloudFormation by referencing its S3 URL.

### Usage in all regions except AWS GovCloud (US)

For using the template in all regions except the AWS GovCloud (US) region prepend

```
https://s3.amazonaws.com/sophos-nsg-cf/
```

to the template filename from the Sophos NSG template repository.

As an example the URL for *utm/autoscaling.template* is

```
https://s3.amazonaws.com/sophos-nsg-cf/utm/autoscaling.template
```

### Usage in AWS GovCloud (US) region

For GovCloud you need to use the following prefix:

```
https://s3-us-gov-west-1.amazonaws.com/sophos-nsg-cf/
```

When using *utm/autoscaling.template* the  URL is

```
https://s3-us-gov-west-1.amazonaws.com/sophos-nsg-cf/utm/autoscaling.template
```

## IAM Permissions

### Autoscaling

#### UTM Worker instances (WorkerPolicy)

| Feature | Statement ID | Service | Action | Resources |
|---------|--------------|---------|--------|-----------|
| configuration synchronization and backup | ConfigSyncAndBackup | S3 | Get\*<br>List\* | S3 Bucket of the stack |
| basic functionality | ReportingSync | S3 | Get\*<br>List\*<br>Delete\*<br>Put\* | S3 Bucket of the stack |

#### UTM Controller instances (UTMPolicy)

| Feature | Statement ID | Service | Action | Resources |
|---------|--------------|---------|--------|-----------|
| basic functionality | DisableSrcDestCheck | EC2 | ModifyInstanceAttribute | \* (1) |
| basic functionality | EipAssociation1 | AutoScaling | DescribeAutoScalingGroups | \* (1) |
| basic functionality | EipAssociation2 | CloudFormation | DescribeStackResources | \* (1) |
| basic functionality | EipAssociation3 | EC2 | AssociateAddress<br>DescribeAddresses<br>DisassociateAddress | \* (1) |
| configuration synchronization and backup | ConfigSyncAndBackup | S3 | \* | S3 bucket of the stack |
| ELB and SG management | WafElbManagement1 | ElasticLoadBalancing | ConfigureHealthCheck<br>CreateLoadBalancerListeners<br>DeleteLoadBalancerListeners<br>SetLoadBalancerPoliciesForBackendServer | ELB of the stack |
| ELB and SG management | WafElbManagement2 | ElasticLoadBalancing | DescribeLoadBalancers<br>DescribeLoadBalancerPolicies | \* (1) |
| ELB and SG management | WafElbManagement3 | CloudFormation | DescribeStackResources | \* (1) |
| ELB and SG management | SecurityGroupManagement1 | EC2 | AuthorizeSecurityGroupEgress<br>AuthorizeSecurityGroupIngress<br>RevokeSecurityGroupEgress<br>RevokeSecurityGroupIngress | only this stack |
| ELB and SG management | SecurityGroupManagement2 | EC2 | DescribeSecurityGroups | \* (1) |
| license pool | LicensePool1 | EC2 | CreateTags | UTM stack |
| license pool | LicensePool2 | EC2 | DescribeInstances | \* (1) |
| license pool | LicensePool3 | S3 | Get\*<br>List\* | stack license pool bucket |
| OGW auto recovery | OGWAutoRecovery | IAM | AttachRolePolicy<br>CreateRole<br>DeleteRole<br>PassRole | EC2ActionsAccess role |
| remote logging | CloudWatchLogging | Logs | CreateLogGroup<br>CreateLogStream<br>PutLogEvents | * |
| UTM update | UtmUpdate1 | AutoScaling | SetDesiredCapacity<br>TerminateInstanceInAutoScalingGroup<br>UpdateAutoScalingGroup | UTM stack |
| UTM update | UtmUpdate2 | AutoScaling | CreateLaunchConfiguration<br>DeleteLaunchConfiguration<br>DescribeAutoScalingGroups<br>DescribeAutoScalingInstances<br>DescribeLaunchConfigurations<br>DescribeScalingActivities<br>DescribeScheduledActions | \* (1) |
| UTM update | UtmUpdate3 | CloudFormation | DescribeStacks | \* (1) |
| UTM update | UtmUpdate4 | CloudFormation | UpdateStack | UTM stack |
| UTM update | UtmUpdate5 | EC2 | DescribeAvailabilityZones<br>DescribeInstances<br>DescribeImages<br>DescribeKeyPairs<br>DescribeSecurityGroups | \* (1) |
| UTM update | UtmUpdate6 | IAM | PassRole | UTM role |
| UTM update | UtmUpdate7 | S3 | Get\*<br>List\* | Sophos template buckets |

(1) AWS does not allow restriction of these permissions on resource level.

#### Outbound Gateway instances (Allow-Describe-EC2-And-ReplaceRoute)

| Service | Action | Resources | Required for |
|---------|--------|-----------|--------------|
| EC2 | DescribeRouteTables<br>DescribeSubnets<br>ReplaceRoute | \* | updating the client network route tables |

#### Outbound Gateway automated management

| Feature | Statement ID | Service | Action | Resources |
|---------|--------------|---------|--------|-----------|
| OGW deployment and monitoring | InitiateDeployment1 | CloudFormation | CreateStack | Sophos OGW templates |
| OGW deployment and monitoring | InitiateDeployment2 | EC2 | DescribeInternetGateways | \* (1) |
| OGW deployment and monitoring | InitiateDeployment3 | S3 | ListBucket | Sophos template bucket |
| OGW deployment and monitoring | InitiateDeployment4 | S3 | GetObject | Sophos template bucket |
| OGW deployment and monitoring | MonitorDeployment1 | CloudFormation | DescribeStacks | \* (1) |
| OGW deployment and monitoring | MonitorDeployment2 | EC2 | DescribeInstances | \* (1) |
| OGW deployment and monitoring | MonitorAndTerminateDeployment | CloudFormation | DeleteStack<br>DescribeStackResources | Stacks with OGW naming scheme |
| OGW stack creation/deletion | ManageOGWStackResources1 | EC2 | AssociateRouteTable<br>AuthorizeSecurityGroupIngress<br>CreateRoute<br>CreateRouteTable<br>CreateSecurityGroup<br>CreateTags<br>DescribeInstances<br>DescribeKeyPairs<br>DescribeRouteTables<br>DescribeSecurityGroups<br>DescribeSubnets<br>DescribeVpcs<br>DisassociateRouteTable<br>ModifyInstanceAttribute | \* (1) |
| OGW stack creation/deletion | ManageOGWStackResources2 | EC2 | RunInstances | Instances with the OGW profile |
| OGW stack creation/deletion | ManageOGWStackResources3 | EC2 | RunInstances | Resources required for launching an instance |
| OGW stack creation/deletion | ManageOGWStackResources4 | EC2 | DeleteRoute<br>DeleteRouteTable<br>DeleteSecurityGroup<br>TerminateInstances | OGW stack resources |
| OGW stack creation/deletion | ManageOGWStackResources5 | IAM | CreateRole<br>DeleteRole<br>DeleteRolePolicy<br>PassRole<br>PutRolePolicy | OGW IAM roles |
| OGW stack creation/deletion | ManageOGWStackResources6 | IAM | AddRoleToInstanceProfile<br>CreateInstanceProfile<br>DeleteInstanceProfile<br>RemoveRoleFromInstanceProfile | IAM profiles with OGW naming scheme |
| OGW stack creation/deletion | ManageOGWStackResources7 | CloudWatch | PutMetricAlarm<br>DeleteAlarms | \* (1) |
| OGW stack creation/deletion | RequiredForCloudWatchPutMetricAlarm | EC2 | DescribeInstanceRecoveryAttribute<br>DescribeInstanceStatus<br>RecoverInstances | \* (1) |
| OGW stack creation/deletion | RequiredForOGWInstancePolicy | EC2 | DescribeRouteTables<br>DescribeSubnets<br>ReplaceRoute | \* (1) |

(1) AWS does not allow restriction of these permissions on resource level.

### High Availability (HA Warm and Cold Standby)

#### All instances (UTMPolicy)

| Service | Action | Resources | Required for |
|---------|--------|-----------|--------------|
| * (except IAM) | \* | \* | the HA feature to manage its resources. We work on limiting the permissions in the future. |
| CloudFormation | UpdateStack | \* | UTM update |
| IAM | PassRole | \* | UTM update |
| Logs | CreateLogGroup<br>CreateLogStream<br>DescribeLogStreams<br>PutLogEvents | \* | sending logs to CloudWatch |
