provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
  
}

resource "aws_instance" "example" {
  ami           = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
}

#here there

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
}

resource "aws_s3_bucket" "example" {

  bucket = "terraform-getting-started-guide"
  acl    = "private"
}

resource "aws_s3_bucket" "example2" {

  bucket = "mah-bucket"
  acl    = "public"
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${aws_subnet.public.*.id}"]

  enable_deletion_protection = true

  access_logs {
    bucket  = "${aws_s3_bucket.lb_logs.bucket}"
    prefix  = "test-lb"
    enabled = true
  }

  tags {
    Environment = "production"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
}

# Create a new replication instance
resource "aws_dms_replication_instance" "test" {
  allocated_storage            = 20
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = "us-west-2c"
  engine_version               = "1.9.0"
  kms_key_arn                  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  multi_az                     = false
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible          = true
  replication_instance_class   = "dms.t2.micro"
  replication_instance_id      = "test-dms-replication-instance-tf"
  replication_subnet_group_id  = "${aws_dms_replication_subnet_group.test-dms-replication-subnet-group-tf}"

  tags {
    Name = "test"
  }

  vpc_security_group_ids = [
    "sg-12345678",
  ]
}

# Create a new load balancer
resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  access_logs {
    bucket        = "foo"
    bucket_prefix = "bar"
    interval      = 60
  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = ["${aws_instance.foo.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "foobar-terraform-elb"
  }
}

# aws launch config
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "as_conf" {
  name          = "web_config"
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
}
# end aws l c

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = "${aws_rds_cluster.default.id}"
  instance_class     = "db.r3.large"
}

resource "aws_rds_cluster" "default" {
  cluster_identifier = "aurora-cluster-demo"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = "barbut8chars"
}


resource "aws_redshift_cluster" "default" {
  cluster_identifier = "tf-redshift-cluster"
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = "Mustbe8characters"
  node_type          = "dc1.large"
  cluster_type       = "single-node"
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 16
  require_lowercase_characters   = false
  require_numbers                = true
  require_uppercase_characters   = false
  require_symbols                = true
  allow_users_to_change_password = true
}

resource "aws_iam_account_password_policy" "strict_2" {
  minimum_password_length        = 16
  require_lowercase_characters   = false
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}
resource "aws_cloudtrail"  "example" {

  is_multi_region_trail = true

  #cloud_watch_logs_group_arn    = "aws:arn::log-group:someLogGroup:"
  event_selector {
    read_write_type = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}



#Ensure a log metric filter and alarm exist for Management Console sign-in without MFA
resource "aws_cloudwatch_log_metric_filter" "MFAUsed" {
  name           = "console-without-mfa"
  pattern        = "{$.eventName = \"ConsoleLogin\" || $.additionalEventData.MFAUsed	!= \"Yes\"}"
  log_group_name = "someLogGroup"

  
  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "UnauthorizedAccess" {
  name           = "console-without-mfa"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for usage of "root" account
resource "aws_cloudwatch_log_metric_filter" "Root" {
  name           = "console-without-mfa"
  pattern        = "{$.userIdentity.type = \"Root\" || $.userIdentity.invokedBy NOT EXISTS || $.eventType != \"AwsServiceEvent\"}"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "DeleteGroupPolicy" {
  name           = "console-without-mfa"
  pattern        = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=Delete UserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "CreateTrail" {
  name           = "console-without-mfa"
  pattern        = "{($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging)}"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for AWS Management Console authentication failures
resource "aws_cloudwatch_log_metric_filter" "consoleLogin" {
  name           = "console-without-mfa"
  pattern        = "{($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\")}"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for disabling or scheduled deletion of customer created CMKs
resource "aws_cloudwatch_log_metric_filter" "CMS" {
  name           = "console-without-mfa"
  pattern        = "{($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey)||($.eventName=ScheduleKeyDeletion))} }"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "s3" {
  name           = "console-without-mfa"
  pattern        = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for AWS Config configuration changes
resource "aws_cloudwatch_log_metric_filter" "KMS" {
  name           = "console-without-mfa"
  pattern        = "{($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder)||($.eventName=DeleteDeliveryChannel)||($.eventName=PutDeliveryChannel)||($.eventName=PutConfigurationRecorder))}"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for security group changes
resource "aws_cloudwatch_log_metric_filter" "AuthorizeSecurityGroupIngress" {
  name           = "console-without-mfa"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup)}"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for changes to Network Access Control Lists (NACL)
resource "aws_cloudwatch_log_metric_filter" "CreateNetworkAcl" {
  name           = "console-without-mfa"
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName =
 DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

#Ensure a log metric filter and alarm exist for changes to network gateways
resource "aws_cloudwatch_log_metric_filter" "CreateCustomerGateway" {
  name           = "console-without-mfa"
  pattern        = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName =
 CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}



#Ensure a log metric filter and alarm exist for route table changes
resource "aws_cloudwatch_log_metric_filter" "CreateRoute" {
  name           = "console-without-mfa"
  pattern        = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}


#Ensure a log metric filter and alarm exist for VPC changes
resource "aws_cloudwatch_log_metric_filter" "CreateVpc" {
  name           = "console-without-mfa"
  pattern        = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) ||($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
  log_group_name = "someLogGroup"

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "someNamespace"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_without_mfa" {
  alarm_name          = "console-without-mfa-us-west-2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleWithoutMFACount"
  namespace           = "someNamespace"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Use of the console by an account without MFA has been detected"
  alarm_actions       = ["someTopic"]
}

resource "aws_sns_topic" "security_alerts" {
  name  = "someTopic"
  arn   = "someTopic"

}

#Ensure none of the roles have assume role permission for all the accounts

resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "someTopic"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#Ensure no security groups allow ingress from 0.0.0.0/0 to port 3389

resource "aws_security_group" "allow_3389" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 23
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = ["pl-12c4e678"]
  }
}


#Ensure no security groups allow ingress from 0.0.0.0/0 to port 22
resource "aws_security_group" "allow_22" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = ["pl-12c4e678"]
  }
}

#Ensure SNS topics do not allow global send or subscribe

resource "aws_sns_topic_policy" "sns_policy" {
  arn = "someTopic"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "someTopic"
      },
      "Action": [
        "SNS:Publish",
        "SNS:RemovePermission",
        "SNS:SetTopicAttributes",
        "SNS:DeleteTopic",
        "SNS:ListSubscriptionsByTopic",
        "SNS:GetTopicAttributes",
        "SNS:Receive",
        "SNS:AddPermission",
        "SNS:Subscribe"
      ],
      "Resource": "arn:aws:sns:us-west-2:054106316361:someTopic",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "054106316361"
        }
      }
    },
    {
      "Sid": "__console_pub_0",
      "Effect": "Allow",
      "Principal": {
        "AWS": "someTopic"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:us-west-2:054106316361:someTopic"
    },
    {
      "Sid": "__console_sub_0",
      "Effect": "Allow",
      "Principal": {
        "AWS": "someTopic"
      },
      "Action": [
        "SNS:Subscribe",
        "SNS:Receive"
      ],
      "Resource": "arn:aws:sns:us-west-2:054106316361:someTopic"
    }
  ]
}
EOF
}