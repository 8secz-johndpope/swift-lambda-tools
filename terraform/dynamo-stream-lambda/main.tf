#Build 

variable "build_params" {
  type = "map"
}

variable "env" {
  type = "map"
  default = {}
}

# Common
variable "function_name" {
  type = "string"
}

variable "handler" {
  type = "string"
}

# Common Custom
variable "memory_size" {
  type    = "string"
  default = "256"
}

variable "timeout" {
  type    = "string"
  default = "180"
}

# Dynamo Stream

variable "stream_arn" {
  type = "string"
}


resource "aws_lambda_function" "lambda" {
  filename         = "${var.build_params["zip_file"]}"
  function_name    = "${var.function_name}"
  role             = "${var.build_params["role"]}"
  handler          = "${var.handler}"
  runtime          = "provided"
  memory_size      = "${var.memory_size}"
  timeout          = "${var.timeout}"
  publish          = true
  layers           = ["${var.build_params["runtime_layer"]}"]
  source_code_hash = "${var.build_params["zip_file_hash"]}"

  environment {
    variables = "${var.env}"
  }
}

resource "aws_lambda_event_source_mapping" "lambda" {
  batch_size        = 100
  event_source_arn  = "${var.stream_arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.lambda.arn}"
  starting_position = "LATEST"
}