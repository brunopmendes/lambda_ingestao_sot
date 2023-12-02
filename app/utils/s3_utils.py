import boto3

class S3Utils:
    def __init__(self):
        self.s3_client = boto3.client('s3')

    def download_file(self, bucket, key, local_path):
        try:
            self.s3_client.download_file(bucket, key, local_path)
        except Exception as e:
            print(f"Erro ao baixar o arquivo do S3: {str(e)}")

    
    def upload_file(self, local_path, bucket, key):
        try:
            self.s3_client.upload_file(local_path, bucket, key)
        except Exception as e:
            print(f"Erro ao fazer upload do arquivo para o S3: {str(e)}")

    
    def check_file_exists(self, bucket, key):
        try:
            self.s3_client.head_object(Bucket=bucket, Key=key)
            return True
        except Exception as e:
            return False