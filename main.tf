provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_stream" "sentiment_stream" {
  name         = "social-media-stream"
  shard_count  = 1
}

resource "aws_s3_bucket" "sentiment_data" {
  bucket = "social-media-sentiment-data"
}

resource "aws_redshift_cluster" "sentiment_cluster" {
  cluster_identifier = "sentimentdb"
  database_name      = "sentimentdb"
  node_type          = "dc2.large"
  cluster_type       = "single-node"
  master_username    = "admin"
  master_password    = "yourpassword"
}

resource "aws_lambda_function" "sentiment_lambda" {
  function_name = "SentimentAnalysisLambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_api_gateway_rest_api" "sentiment_api" {
  name        = "sentiment-api"
  description = "API to fetch sentiment data"
}

resource "aws_api_gateway_resource" "sentiment_resource" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  parent_id   = aws_api_gateway_rest_api.sentiment_api.root_resource_id
  path_part   = "sentiment"
}

resource "aws_api_gateway_method" "get_sentiment" {
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  resource_id   = aws_api_gateway_resource.sentiment_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.sentiment_api.id
  resource_id             = aws_api_gateway_resource.sentiment_resource.id
  http_method             = aws_api_gateway_method.get_sentiment.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.sentiment_lambda.arn}/invocations"
}
