#Build 

variable "runtime_layers" {
  type    = list(string)
  default = []
}
variable "build_params" {
  type = map(string)
}

variable "env" {
  type    = map(string)
  default = {}
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

# Common
variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

# Common Custom
variable "reserved_concurrent_executions" {
  type    = number
  default = -1
}

variable "memory_size" {
  type    = string
  default = "256"
}

variable "timeout" {
  type    = string
  default = "180"
}

# SQS

variable "sqs_arn" {
  type = string
}


resource "aws_lambda_function" "lambda" {
  filename                       = var.build_params["zip_file"]
  function_name                  = var.function_name
  role                           = var.build_params["role"]
  handler                        = var.handler
  runtime                        = "provided"
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  publish                        = true
  layers                         = var.runtime_layers
  reserved_concurrent_executions = var.reserved_concurrent_executions
  source_code_hash               = var.build_params["zip_file_hash"]

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = var.env
  }
}

resource "aws_lambda_event_source_mapping" "lambda" {
  batch_size       = 10
  event_source_arn = var.sqs_arn
  enabled          = true
  function_name    = aws_lambda_function.lambda.arn
}
