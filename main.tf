terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "rahul_p21_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = <<-SCRIPT
              #!/bin/bash
              apt-get update -y
              apt-get install -y stress-ng
              nohup stress-ng --cpu 1 --cpu-load 45 --timeout 3600s >/dev/null 2>&1 &
              SCRIPT

  tags = {
    Name    = "rahul-p21-monitored-ec2"
    Project = "P21-CloudWatch-Monitoring-Dashboard"
  }
}

resource "aws_cloudwatch_dashboard" "rahul_p21_dashboard" {
  dashboard_name = "rahul-p21-performance-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EC2 CPU Utilization (%) - rahul-p21-monitored-ec2"
          region  = "ap-south-1"
          stat    = "Average"
          period  = 60
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.rahul_p21_ec2.id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Network Traffic (Bytes) - In vs Out"
          region  = "ap-south-1"
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.rahul_p21_ec2.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.rahul_p21_ec2.id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Network Packets - In vs Out"
          region  = "ap-south-1"
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "NetworkPacketsIn", "InstanceId", aws_instance.rahul_p21_ec2.id],
            ["AWS/EC2", "NetworkPacketsOut", "InstanceId", aws_instance.rahul_p21_ec2.id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Instance Health & Status Checks"
          region  = "ap-south-1"
          stat    = "Maximum"
          period  = 60
          view    = "singleValue"
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.rahul_p21_ec2.id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.rahul_p21_ec2.id]
          ]
        }
      }
    ]
  })
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.rahul_p21_dashboard.dashboard_name
}

output "monitored_instance_id" {
  value = aws_instance.rahul_p21_ec2.id
}
