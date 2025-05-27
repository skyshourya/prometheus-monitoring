# Create IAM User
resource "aws_iam_user" "prometheus_user" {
  name = "prometheus_monitoring_user"
  path = "/"
}

# Create Access Keys for the IAM User
resource "aws_iam_access_key" "prometheus_user_key" {
  user = aws_iam_user.prometheus_user.name
}

# Create IAM Policy for Prometheus
resource "aws_iam_policy" "prometheus_policy" {
  name        = "prometheus_terraform_role_policy"
  description = "Enhanced permissions for Prometheus discovery"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:CreatePolicy",
          "iam:ListRolePolicies",
          "iam:GetPolicyVersion",
          "iam:GetPolicy",
          "iam:AttachRolePolicy",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:ListPolicyVersions",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "iam:PassedToService": "ec2.amazonaws.com"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribePolicies"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:DeletePolicy",
          "iam:DeleteRole",
          "iam:DetachRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        "Resource": "*"
      }
    ]
  })
}

# Create IAM Role for EC2 instances
resource "aws_iam_role" "prometheus_role" {
  name = "prometheus_terraform_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "prometheus_role_policy_attachment" {
  role       = aws_iam_role.prometheus_role.name
  policy_arn = aws_iam_policy.prometheus_policy.arn
}

# Attach Policy to User
resource "aws_iam_user_policy_attachment" "prometheus_user_policy_attachment" {
  user       = aws_iam_user.prometheus_user.name
  policy_arn = aws_iam_policy.prometheus_policy.arn
}

# Create Instance Profile
resource "aws_iam_instance_profile" "prometheus_profile" {
  name = "prometheus_terraform_profile"
  role = aws_iam_role.prometheus_role.name
}

# Output the access keys (be careful with these in production)
output "prometheus_user_access_key" {
  value     = aws_iam_access_key.prometheus_user_key.id
  sensitive = false
}

output "prometheus_user_secret_key" {
  value     = aws_iam_access_key.prometheus_user_key.secret
  sensitive = true
}
