## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.37, < 7.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.7.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kms_cloudtrail"></a> [kms\_cloudtrail](#module\_kms\_cloudtrail) | terraform-aws-modules/kms/aws | ~> 4.2 |
| <a name="module_kms_main"></a> [kms\_main](#module\_kms\_main) | terraform-aws-modules/kms/aws | ~> 4.2 |
| <a name="module_kms_terraform_state"></a> [kms\_terraform\_state](#module\_kms\_terraform\_state) | terraform-aws-modules/kms/aws | ~> 4.2 |
| <a name="module_s3_cloudtrail_logs"></a> [s3\_cloudtrail\_logs](#module\_s3\_cloudtrail\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 5.11 |
| <a name="module_s3_cloudtrail_logs_logging"></a> [s3\_cloudtrail\_logs\_logging](#module\_s3\_cloudtrail\_logs\_logging) | terraform-aws-modules/s3-bucket/aws | ~> 5.11 |
| <a name="module_s3_prod_vpc_flow_logs"></a> [s3\_prod\_vpc\_flow\_logs](#module\_s3\_prod\_vpc\_flow\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 5.11 |
| <a name="module_s3_terraform_state"></a> [s3\_terraform\_state](#module\_s3\_terraform\_state) | terraform-aws-modules/s3-bucket/aws | ~> 5.11 |
| <a name="module_s3_terraform_state_logs"></a> [s3\_terraform\_state\_logs](#module\_s3\_terraform\_state\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 5.11 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 6.6 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.ec2_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.ec2_system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_metric_filter.iba_orders_zero_orders](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.iba_orders_zero_orders_detected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_eip.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.prod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_instance_profile.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.cloudtrail_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudtrail_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.prod_bastion_cloudwatch_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.prod_bastion_ssm_core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_launch_template.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.prod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.prod_bastion_all_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.prod_bastion_mongodb_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.prod_bastion_ssh_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_sns_topic.alarm_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.alarm_email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_ssm_association.iba_orders_sync_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_document.iba_orders_sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_parameter.iba_orders_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.iba_orders_google_credentials_json](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.mongodb_root_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [local_file.prod_bastion_pem](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_password.mongodb_root](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_uuid.terraform_backend](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [tls_private_key.prod_bastion](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_notification_email"></a> [alarm\_notification\_email](#input\_alarm\_notification\_email) | Email address to receive CloudWatch alarm notifications | `string` | `"rob.hough@gmail.com"` | no |
| <a name="input_alarm_sns_topic_name"></a> [alarm\_sns\_topic\_name](#input\_alarm\_sns\_topic\_name) | SNS topic name for CloudWatch alarm notifications | `string` | `"iba-cloudwatch-alarms"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where resources will be created | `string` | `"us-east-1"` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | EC2 instance type for bastion/test instance | `string` | `"t3.micro"` | no |
| <a name="input_cloudwatch_docker_log_group_name"></a> [cloudwatch\_docker\_log\_group\_name](#input\_cloudwatch\_docker\_log\_group\_name) | CloudWatch Logs group for Docker container logs | `string` | `"/iba/prod/docker/containers"` | no |
| <a name="input_cloudwatch_log_retention_days"></a> [cloudwatch\_log\_retention\_days](#input\_cloudwatch\_log\_retention\_days) | Retention period in days for EC2 and Docker CloudWatch log groups | `number` | `14` | no |
| <a name="input_cloudwatch_system_log_group_name"></a> [cloudwatch\_system\_log\_group\_name](#input\_cloudwatch\_system\_log\_group\_name) | CloudWatch Logs group for EC2 system and bootstrap logs | `string` | `"/iba/prod/ec2/system"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | <pre>{<br/>  "CreatedAt": "2026-03-25",<br/>  "ManagedBy": "Terraform",<br/>  "Organization": "Indiana Blacksmithing Association"<br/>}</pre> | no |
| <a name="input_enable_encryption"></a> [enable\_encryption](#input\_enable\_encryption) | Enable encryption for resources that support it | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_iba_orders_api_key"></a> [iba\_orders\_api\_key](#input\_iba\_orders\_api\_key) | Squarespace API key for iba\_orders | `string` | `""` | no |
| <a name="input_iba_orders_api_key_ssm_parameter_name"></a> [iba\_orders\_api\_key\_ssm\_parameter\_name](#input\_iba\_orders\_api\_key\_ssm\_parameter\_name) | SSM parameter name for iba\_orders API key | `string` | `"/iba/prod/iba_orders/api_key"` | no |
| <a name="input_iba_orders_container_name"></a> [iba\_orders\_container\_name](#input\_iba\_orders\_container\_name) | Container name for iba\_orders job | `string` | `"iba-orders-sync"` | no |
| <a name="input_iba_orders_days_back"></a> [iba\_orders\_days\_back](#input\_iba\_orders\_days\_back) | Days of order history to fetch | `number` | `30` | no |
| <a name="input_iba_orders_enable_schedule"></a> [iba\_orders\_enable\_schedule](#input\_iba\_orders\_enable\_schedule) | Enable scheduled execution of iba\_orders via SSM association | `bool` | `true` | no |
| <a name="input_iba_orders_env_file_ssm_parameter_name"></a> [iba\_orders\_env\_file\_ssm\_parameter\_name](#input\_iba\_orders\_env\_file\_ssm\_parameter\_name) | SSM parameter name containing full .env content for iba\_orders | `string` | `"/iba/prod/iba_orders/env_file"` | no |
| <a name="input_iba_orders_google_credentials_json"></a> [iba\_orders\_google\_credentials\_json](#input\_iba\_orders\_google\_credentials\_json) | Optional Google service-account JSON content | `string` | `""` | no |
| <a name="input_iba_orders_google_credentials_ssm_parameter_name"></a> [iba\_orders\_google\_credentials\_ssm\_parameter\_name](#input\_iba\_orders\_google\_credentials\_ssm\_parameter\_name) | SSM parameter name for Google service-account JSON | `string` | `"/iba/prod/iba_orders/google_credentials_json"` | no |
| <a name="input_iba_orders_google_members_worksheet"></a> [iba\_orders\_google\_members\_worksheet](#input\_iba\_orders\_google\_members\_worksheet) | Google worksheet for members | `string` | `"members"` | no |
| <a name="input_iba_orders_google_sheet_id"></a> [iba\_orders\_google\_sheet\_id](#input\_iba\_orders\_google\_sheet\_id) | Optional Google Sheet ID for orders sync | `string` | `""` | no |
| <a name="input_iba_orders_google_worksheet"></a> [iba\_orders\_google\_worksheet](#input\_iba\_orders\_google\_worksheet) | Google worksheet for orders | `string` | `"orders_v2"` | no |
| <a name="input_iba_orders_http_timeout_seconds"></a> [iba\_orders\_http\_timeout\_seconds](#input\_iba\_orders\_http\_timeout\_seconds) | HTTP timeout for iba\_orders API calls | `number` | `30` | no |
| <a name="input_iba_orders_repo_ref"></a> [iba\_orders\_repo\_ref](#input\_iba\_orders\_repo\_ref) | Git branch, tag, or commit to deploy for iba\_orders | `string` | `"main"` | no |
| <a name="input_iba_orders_repo_url"></a> [iba\_orders\_repo\_url](#input\_iba\_orders\_repo\_url) | Git repository URL for the iba\_orders project | `string` | `"https://github.com/rch317/iba_orders.git"` | no |
| <a name="input_iba_orders_schedule_expression"></a> [iba\_orders\_schedule\_expression](#input\_iba\_orders\_schedule\_expression) | Schedule expression for iba\_orders SSM association | `string` | `"rate(1 day)"` | no |
| <a name="input_iba_orders_store_id"></a> [iba\_orders\_store\_id](#input\_iba\_orders\_store\_id) | Optional Squarespace store ID for iba\_orders | `string` | `""` | no |
| <a name="input_mongodb_access_cidrs"></a> [mongodb\_access\_cidrs](#input\_mongodb\_access\_cidrs) | CIDR blocks allowed to access MongoDB directly (leave empty to use SSM port forwarding only) | `list(string)` | `[]` | no |
| <a name="input_mongodb_container_name"></a> [mongodb\_container\_name](#input\_mongodb\_container\_name) | Container name for MongoDB | `string` | `"mongodb"` | no |
| <a name="input_mongodb_data_dir"></a> [mongodb\_data\_dir](#input\_mongodb\_data\_dir) | Host path for MongoDB persistent data | `string` | `"/opt/mongodb/data"` | no |
| <a name="input_mongodb_image"></a> [mongodb\_image](#input\_mongodb\_image) | MongoDB container image to run on the bastion/test host | `string` | `"mongo:7"` | no |
| <a name="input_mongodb_password_ssm_parameter_name"></a> [mongodb\_password\_ssm\_parameter\_name](#input\_mongodb\_password\_ssm\_parameter\_name) | SSM Parameter Store name for MongoDB root password | `string` | `"/iba/prod/mongodb/root_password"` | no |
| <a name="input_mongodb_port"></a> [mongodb\_port](#input\_mongodb\_port) | Port to expose MongoDB on the EC2 host | `number` | `27017` | no |
| <a name="input_mongodb_username"></a> [mongodb\_username](#input\_mongodb\_username) | Root username for MongoDB | `string` | `"mongodb_admin"` | no |
| <a name="input_prod_subnet_az_count"></a> [prod\_subnet\_az\_count](#input\_prod\_subnet\_az\_count) | Number of availability zones to use for prod public and private subnets | `number` | `3` | no |
| <a name="input_prod_vpc_cidr"></a> [prod\_vpc\_cidr](#input\_prod\_vpc\_cidr) | Primary CIDR block for the prod VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | `"iba"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_notification_email"></a> [alarm\_notification\_email](#output\_alarm\_notification\_email) | Configured email endpoint for alarm notifications |
| <a name="output_alarm_notification_sns_topic_arn"></a> [alarm\_notification\_sns\_topic\_arn](#output\_alarm\_notification\_sns\_topic\_arn) | SNS topic ARN used for CloudWatch alarm notifications |
| <a name="output_cloudtrail_arn"></a> [cloudtrail\_arn](#output\_cloudtrail\_arn) | ARN of the CloudTrail |
| <a name="output_cloudtrail_bucket_name"></a> [cloudtrail\_bucket\_name](#output\_cloudtrail\_bucket\_name) | Name of the S3 bucket for CloudTrail logs |
| <a name="output_cloudtrail_kms_key_alias"></a> [cloudtrail\_kms\_key\_alias](#output\_cloudtrail\_kms\_key\_alias) | Alias of the CloudTrail KMS key |
| <a name="output_cloudtrail_kms_key_arn"></a> [cloudtrail\_kms\_key\_arn](#output\_cloudtrail\_kms\_key\_arn) | ARN of the CloudTrail KMS key |
| <a name="output_cloudtrail_kms_key_id"></a> [cloudtrail\_kms\_key\_id](#output\_cloudtrail\_kms\_key\_id) | ID of the CloudTrail KMS key |
| <a name="output_cloudwatch_docker_log_group_name"></a> [cloudwatch\_docker\_log\_group\_name](#output\_cloudwatch\_docker\_log\_group\_name) | CloudWatch log group for Docker container logs |
| <a name="output_cloudwatch_system_log_group_name"></a> [cloudwatch\_system\_log\_group\_name](#output\_cloudwatch\_system\_log\_group\_name) | CloudWatch log group for EC2 system logs |
| <a name="output_iba_orders_api_key_ssm_parameter_name"></a> [iba\_orders\_api\_key\_ssm\_parameter\_name](#output\_iba\_orders\_api\_key\_ssm\_parameter\_name) | SSM Parameter Store name for iba\_orders API key |
| <a name="output_iba_orders_env_file_ssm_parameter_name"></a> [iba\_orders\_env\_file\_ssm\_parameter\_name](#output\_iba\_orders\_env\_file\_ssm\_parameter\_name) | SSM Parameter Store name for full iba\_orders .env content |
| <a name="output_iba_orders_google_credentials_ssm_parameter_name"></a> [iba\_orders\_google\_credentials\_ssm\_parameter\_name](#output\_iba\_orders\_google\_credentials\_ssm\_parameter\_name) | SSM Parameter Store name for optional Google credentials JSON |
| <a name="output_iba_orders_run_now_command"></a> [iba\_orders\_run\_now\_command](#output\_iba\_orders\_run\_now\_command) | Run iba\_orders sync job immediately via SSM |
| <a name="output_iba_orders_ssm_document_name"></a> [iba\_orders\_ssm\_document\_name](#output\_iba\_orders\_ssm\_document\_name) | SSM document name to run iba\_orders sync job |
| <a name="output_iba_orders_zero_orders_alarm_name"></a> [iba\_orders\_zero\_orders\_alarm\_name](#output\_iba\_orders\_zero\_orders\_alarm\_name) | CloudWatch alarm name that triggers when zero orders are fetched |
| <a name="output_iba_orders_zero_orders_metric_name"></a> [iba\_orders\_zero\_orders\_metric\_name](#output\_iba\_orders\_zero\_orders\_metric\_name) | CloudWatch metric name incremented when zero orders are fetched |
| <a name="output_kms_key_alias"></a> [kms\_key\_alias](#output\_kms\_key\_alias) | Alias of the main KMS key |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the main KMS key |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the main KMS key |
| <a name="output_mongodb_local_connection_string"></a> [mongodb\_local\_connection\_string](#output\_mongodb\_local\_connection\_string) | Connection string after starting SSM port forwarding and retrieving password from SSM |
| <a name="output_mongodb_password_ssm_parameter_name"></a> [mongodb\_password\_ssm\_parameter\_name](#output\_mongodb\_password\_ssm\_parameter\_name) | SSM Parameter Store name containing MongoDB root password |
| <a name="output_mongodb_ssm_port_forward_command"></a> [mongodb\_ssm\_port\_forward\_command](#output\_mongodb\_ssm\_port\_forward\_command) | Start an SSM port-forward session from localhost to MongoDB on the EC2 host |
| <a name="output_prod_bastion_instance_id"></a> [prod\_bastion\_instance\_id](#output\_prod\_bastion\_instance\_id) | Instance ID of the prod bastion/test instance |
| <a name="output_prod_bastion_key_file"></a> [prod\_bastion\_key\_file](#output\_prod\_bastion\_key\_file) | Path to the private key file (save this for SSH access) |
| <a name="output_prod_bastion_key_name"></a> [prod\_bastion\_key\_name](#output\_prod\_bastion\_key\_name) | Name of the SSH key pair for the bastion instance |
| <a name="output_prod_bastion_private_ip"></a> [prod\_bastion\_private\_ip](#output\_prod\_bastion\_private\_ip) | Private IP address of the prod bastion instance |
| <a name="output_prod_bastion_public_ip"></a> [prod\_bastion\_public\_ip](#output\_prod\_bastion\_public\_ip) | Public IP address of the prod bastion instance |
| <a name="output_prod_bastion_security_group_id"></a> [prod\_bastion\_security\_group\_id](#output\_prod\_bastion\_security\_group\_id) | Security group ID for the bastion instance |
| <a name="output_prod_bastion_ssh_command"></a> [prod\_bastion\_ssh\_command](#output\_prod\_bastion\_ssh\_command) | SSH command to connect to the bastion instance |
| <a name="output_prod_internet_gateway_id"></a> [prod\_internet\_gateway\_id](#output\_prod\_internet\_gateway\_id) | ID of the prod internet gateway |
| <a name="output_prod_private_subnet_ids"></a> [prod\_private\_subnet\_ids](#output\_prod\_private\_subnet\_ids) | IDs of the prod private subnets |
| <a name="output_prod_public_subnet_ids"></a> [prod\_public\_subnet\_ids](#output\_prod\_public\_subnet\_ids) | IDs of the prod public subnets |
| <a name="output_prod_vpc_cidr"></a> [prod\_vpc\_cidr](#output\_prod\_vpc\_cidr) | CIDR block of the prod VPC |
| <a name="output_prod_vpc_id"></a> [prod\_vpc\_id](#output\_prod\_vpc\_id) | ID of the prod VPC |
| <a name="output_terraform_state_bucket"></a> [terraform\_state\_bucket](#output\_terraform\_state\_bucket) | Name of the S3 bucket for Terraform state |
| <a name="output_terraform_state_bucket_arn"></a> [terraform\_state\_bucket\_arn](#output\_terraform\_state\_bucket\_arn) | ARN of the S3 bucket for Terraform state |
| <a name="output_terraform_state_kms_key_id"></a> [terraform\_state\_kms\_key\_id](#output\_terraform\_state\_kms\_key\_id) | ID of the KMS key for Terraform state encryption |
