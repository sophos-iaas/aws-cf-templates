# Sophos NSG CloudFormation Templates

This repository tracks the templates used within the Sophos NSG CloudFormation template S3 bucket *s3://sophos-nsg-cf/*

## Usage

You can use any of the templates with CloudFormation by referencing its S3 URL.

### Usage in all regions except AWS GovCloud (US)

For using the template in all regions except the AWS GovCloud (US) region prepend

```
https://s3.amazonaws.com/sophos-nsg-cf/
```

to the template filename from the Sophos NSG template repository.

As an example the URL for *utm/utm-latest-autoscaling.template* is

```
https://s3.amazonaws.com/sophos-nsg-cf/utm/utm-latest-autoscaling.template
```

### Usage in AWS GovCloud (US) region

For GovCloud you need to use the following prefix:

```
https://s3-us-gov-west-1.amazonaws.com/sophos-nsg-cf/
```

When using *utm/utm-latest-autoscaling.template* the  URL is

```
https://s3-us-gov-west-1.amazonaws.com/sophos-nsg-cf/utm/utm-latest-autoscaling.template
```

## IAM Permissions

### Autoscaling

#### Basic Permissions

WorkerPolicy (Used by worker instances)

| Service | Action | Resources | Description |
|---------|--------|-----------|-------------|
| SNS | \* | ConfdSNSTopic | Used to notify UTM workers of configuration changes |
| EC2 | Describe\* | \* | UTM worker requires information about its environment |
| S3 | List\* Get\* | S3 bucket of the stack | Required to share information and configuration between the Controller and the Workers |

UTMPolicy (Used by the Controller)

| Service | Action | Resources | Description |
|---------|--------|-----------|-------------|
| SNS | \* | ConfdSNSTopic | Used to notify workers of configuration changes |
| IAM | PassRole | \* | Required to create instances and setup their permissions |
| IAM | CreateRole | \* | Required for automated OGW deployment and OGW Auto Recovery |
| IAM | PutRolePolicy | \* | Required for automated OGW deployment and OGW Auto Recovery |
| IAM | DeleteRolePolicy | \* | Required for automated OGW deployment and OGW Auto Recovery |
| IAM | CreateInstanceProfile | \* | Required for updating to new UTM versions |
| IAM | AddRoleToInstanceProfile | \* | Required for updating to new UTM versions |
| IAM | RemoveRoleFromInstanceProfile | \* | Required for updating to new UTM versions |
| IAM | DeleteInstanceProfile | \* | Required for updating to new UTM versions |
| IAM | DeleteRole | \* | Required for automated OGW deployment |
| IAM | AttachRolePolicy | arn:aws:iam::\*role/actions/EC2ActionsAccess | Required for OGW Auto Recovery |
| CloudFormation | \* | \* | Unrestricted because of unknown operations that CloudFormation performs in the background |
| EC2 | \* | \* | Most required actions don't allow resource restrictions |
| AutoScaling | \* | \* | Stack deletion and UTM update |
| CloudWatch | \* | \* | Unrestricted because of unknown operations that CloudWatch performs in the background |
| Elastic Load Balancing | \* | ELB of autoscaling stack | Required to reconfigure ELB for WAF |
| Elastic Load Balancing | DescribeLoadBalancers | \* | Required to find our loadbalancer |
| S3 | \* | S3 bucket of the stack, License Pool bucket | Required to upload backups, share UTM configuration and to retrieve license files |
| S3 | List\*, Get\* | Sophos template buckets | CloudFormation templates for conversion and OGW |
| Logs | CreateLogGroup | \* | Used to archive logs |
| Logs | CreateLogStream | \* | Used to archive logs |
| Logs | PutLogEvents | \* | Used to archive logs |
| Logs | DescribeLogStreams | \* | Used to archive logs |

#### Outbound Gateway (OGW)

Allow-Describe-EC2-And-ReplaceRoute (Used by OGW instances)

| Service | Action | Resources | Description |
|---------|--------|-----------|-------------|
| EC2 | DescribeRouteTables | \* | OGW needs to update the client network routes |
| EC2 | DescribeSubnets | \* | OGW needs to update the client network routes |
| EC2 | ReplaceRoute | \* | OGW needs to update the client network routes |

### High Availability (HA Warm and Cold Standby)

UTMPolicy

| Service | Action | Resources | Description |
|---------|--------|-----------|-------------|
| IAM | PassRole | \* | Required for the update of our software |
| CloudFormation | UpdateStack | \* | Required for the update of our software |
| Logs | CreateLogGroup | \* | Used to archive logs |
| Logs | CreateLogStream | \* | Used to archive logs |
| Logs | PutLogEvents | \* | Used to archive logs |
| Logs | DescribeLogStreams | \* | Used to archive logs |
| All except IAM | \* | \* | Full permissions are required by the HA feature to manage its resources. We work on limiting the permissions in the future. |
