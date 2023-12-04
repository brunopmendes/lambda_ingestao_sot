provider "aws" {
  region  = "us-east-1"
  profile = "bruno_mendes"
}

resource "aws_lambda_function" "lambda_ingestao_sot" {
  filename      = data.archive_file.lambda_my_function.output_path
  function_name = "lambda_ingestao_sot"
  role          = aws_iam_role.lambda_role.arn
  description   = "Lambda captura alterações nos buckets da sor e os coloca na sot"

  handler = "lambda_handler.lambda_handler"
  runtime = "python3.9"

  layers = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:11"]

  source_code_hash = filebase64sha256(data.archive_file.lambda_my_function.output_path) #hash para capturar qualquer alteracao na lambda

  environment {
    variables = {
      S3_BUCKET_SOR_NAME = "bucket-sor-794741686432"
      S3_BUCKET_SOT_NAME = "bucket-sot-794741686432"
    }
  }
}


#### PERMISSOES IAM ####
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "Policy for Lambda function"

  policy = file("${path.module}/policies/lambda_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = file("${path.module}/trust/lambda_trust_policy.json")
}

#### TRIGGERS DA LAMBDA ####
# importar o bucket da sua conta com o 'terraform import terraform import aws_s3_bucket.bucket_sor arn_do_seu_bucket'
resource "aws_s3_bucket" "bucket_sor" {
     bucket = var.S3_BUCKET_NAME_SOR
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ingestao_sot.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_sor.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket_sor.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_ingestao_sot.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "sor_tb1_dow_jones/"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_ingestao_sot.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "sor_tb2_msci/"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# CRIA ZIP PARA LAMBDA
data "archive_file" "lambda_my_function" {
  type             = "zip"
  source_dir      = "${path.module}/../app/"
  output_file_mode = "0666"
  output_path      = "${path.module}/../out/lambda_handler.zip"
}
