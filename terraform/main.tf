# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "django_lambda_example_ecr" {
  source = "terraform-aws-modules/lambda/aws//modules/docker-build"

  create_ecr_repo = true
  ecr_repo        = "django_lambda_example"
  image_tag       = "latest"
  source_path     = "context"
}

module "django_lambda_example_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "django_lambda_example"
  description   = "One lambda to rule them all"

  create_package = false

  image_uri    = module.django_lambda_example_ecr.image_uri
  package_type = "Image"

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.django_lambda_example_apig.apigatewayv2_api_execution_arn}/*/*"
    }
  }

  create_current_version_allowed_triggers = false

}

module "django_lambda_example_apig" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "django_lambda_example_http_apig"
  description   = "Django lambda example HTTP API Gateway"
  protocol_type = "HTTP"
  create_api_domain_name = false

  tags = {
    Name = "django_lambda_example_http_apig"
  }

  integrations = {
    "ANY /{proxy+}" = {
      lambda_arn = module.django_lambda_example_lambda.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds = 12000
    }
  }
}

resource "local_file" "update_lambda" {
  filename = "update-lambda.sh"
  content = <<EOF
#!/bin/bash
aws ecr get-login-password --region ${data.aws_region.current.id} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com
docker build -t django_lambda_example ../
docker tag django_lambda_example:latest ${module.django_lambda_example_ecr.image_uri}
docker push ${module.django_lambda_example_ecr.image_uri}
aws lambda update-function-code --function-name ${module.django_lambda_example_lambda.lambda_function_name} --image-uri ${module.django_lambda_example_ecr.image_uri}
EOF
}


