from fastapi import FastAPI
import boto3
import json
import os

app = FastAPI()

# Initialize Kinesis client
region_name = os.environ.get("AWS_REGION", "us-east-1")  # Use environment variable or default to us-east-1
kinesis_client = boto3.client('kinesis', region_name=region_name)

@app.get("/")
def home():
    return {"message": "Social Media Sentiment API is running!"}

@app.get("/sentiment/{keyword}")
def get_sentiment(keyword: str):
    """Fetches real-time sentiment data from Kinesis for a given keyword."""
    try:
        response = kinesis_client.get_shard_iterator(
            StreamName="social-media-stream",
            ShardId="shardId-000000000000",
            ShardIteratorType="LATEST"
        )

        shard_iterator = response['ShardIterator']
        records_response = kinesis_client.get_records(ShardIterator=shard_iterator)

        sentiment_data = []
        for record in records_response['Records']:
            try:
                data = record['Data'].decode('utf-8')
                sentiment_data.append(json.loads(data))
            except json.JSONDecodeError:
                print(f"Error decoding JSON: {data}")
                continue  # Skip to the next record

        return {"keyword": keyword, "sentiment": sentiment_data}

    except Exception as e:
        print(f"Error fetching sentiment data: {e}")
        return {"keyword": keyword, "sentiment": [], "error": str(e)}
