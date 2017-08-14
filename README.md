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

| Service | Action | Resources | Required for |
|---------|--------|-----------|--------------|
| S3 | Get\*<br>List\* | S3 bucket of the stack | sharing information and configuration between UTM Workers and the Controller |
| S3 | Delete\*<br>Get\*<br>List\*<br>Put\* | "adbs" folder in S3 bucket of the stack | sending reporting and statistical data to the Controller |

#### UTM Controller instances (UTMPolicy)

| Service | Action | Resources | Required for |
|---------|--------|-----------|--------------|
| AutoScaling | SetDesiredCapacity<br>TerminateInstanceInAutoScalingGroup<br>UpdateAutoScalingGroup | UTM stack| UTM update |
| AutoScaling | CreateLaunchConfiguration<br>DeleteLaunchConfiguration<br>DescribeAutoScalingGroups<br>DescribeAutoScalingInstances<br>DescribeLaunchConfigurations<br>DescribeScalingActivities<br>DescribeScheduledActions | \* (1) | UTM update |
| CloudFormation | \* | \* | automated OGW deployment |
| CloudFormation | DescribeStackResources<br>DescribeStacks | \* (1) | UTM update |
| CloudFormation | UpdateStack | UTM stack | UTM update |
| CloudWatch | DeleteAlarms<br>PutMetricAlarm | \* | OGW Auto Recovery |
| EC2 | \* | \* | automated OGW deployment |
| EC2 | AssociateAddress<br>Describe*<br>ModifyInstanceAttribute | \* (1) | association of EIP, configuration the UTM instance and checking for updates |
| EC2 | \* | UTM stack | instance management |
| ElasticLoadBalancing | \* | ELB of the stack | configuration of ELB for WAF feature |
| ElasticLoadBalancing | DescribeLoadBalancerPolicies<br>DescribeLoadBalancers | \* (1) | configuration of ELB for WAF feature |
| IAM | CreateRole<br>DeleteRole | \* | automated OGW deployment and OGW Auto Recovery |
| IAM | AddRoleToInstanceProfile<br>CreateInstanceProfile<br>DeleteInstanceProfile<br>DeleteRolePolicy<br>PassRole<br>PutRolePolicy<br>RemoveRoleFromInstanceProfile | \* | automated OGW deployment |
| IAM | AttachRolePolicy | arn:aws:iam::\*role/actions/EC2ActionsAccess | OGW Auto Recovery |
| Logs | CreateLogGroup<br>CreateLogStream<br>DescribeLogStreams<br>PutLogEvents | \* | sending logs to CloudWatch |
| S3 | \* | S3 bucket of the stack | uploading backups, sharing UTM configuration and retrieving reporting data |
| S3 | Get\*<br>List\* | stack License Pool bucket / Sophos template buckets | License Pool feature / UTM update, conversion and automated OGW deployment |


(1) AWS does not allow restriction of these permissions on resource level.

#### Outbound Gateway instances (Allow-Describe-EC2-And-ReplaceRoute)

| Service | Action | Resources | Required for |
|---------|--------|-----------|--------------|
| EC2 | DescribeRouteTables<br>DescribeSubnets<br>ReplaceRoute | \* | updating the client network route tables |

### High Availability (HA Warm and Cold Standby)

#### All instances (UTMPolicy)

| Service | Action | Resources | Required for |
|---------|--------|-----------|--------------|
| * (except IAM) | \* | \* | the HA feature to manage its resources. We work on limiting the permissions in the future. |
| CloudFormation | UpdateStack | \* | UTM update |
| IAM | PassRole | \* | UTM update |
| Logs | CreateLogGroup<br>CreateLogStream<br>DescribeLogStreams<br>PutLogEvents | \* | sending logs to CloudWatch |
