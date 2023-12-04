import json
import boto3
import pandas as pd
import os
from datetime import datetime

from utils.s3_utils import S3Utils
s3_utils = S3Utils()

def load_tables_mapping():
    with open('configs/tables_mapping.json', 'r') as teste:
        tables_mapping = json.load(teste)
    return tables_mapping

def lambda_handler(event, context):

    _S3_BUCKET_NAME_SOT = os.getenv('S3_BUCKET_SOT_NAME')
    _S3_BUCKET_NAME_SOR = os.getenv('S3_BUCKET_SOR_NAME')
    
    print('deu bom')
    tables_mapping = load_tables_mapping()['sor_buckets']


    record = event['Records'][0]

    bucket_name = record['s3']['bucket']['name']
    key = record['s3']['object']['key']

    process_sor_bucket(bucket_name, key, tables_mapping, _S3_BUCKET_NAME_SOT)
    
    
def process_sor_bucket(bucket_name, key, tables_mapping, sot_bucket_name):
    
    sor_buckets = tables_mapping

    prefix = key.split('/')[0]

    file_name = os.path.basename(key)
    local_path = f"/tmp/{file_name}"

    sor_columns = sor_buckets[prefix]

    s3_utils.download_file(bucket_name, key, local_path)

    df_sor = pd.read_csv(local_path, usecols=sor_columns, sep=';')   
    
    local_path_sot_csv = f'/tmp/{prefix}.csv'
    df_sor.to_csv(local_path_sot_csv)

    date = datetime.now()
    s3_utils.upload_file(local_path=local_path_sot_csv, bucket=sot_bucket_name, key=f'sot_tb_consolida/{prefix}-{date:%Y%m%d}.csv')
