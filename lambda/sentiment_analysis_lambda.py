import json
import boto3
import re
from textblob import TextBlob

def lambda_handler(event, context):
    """
    AWS Lambda function for sentiment analysis of text input.
    """

    # Get the text from the event payload
    text = event.get("text", "")

    if not text:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No text provided for analysis."})
        }

    # Perform sentiment analysis
    analysis = TextBlob(text)
    sentiment_score = analysis.sentiment.polarity

    # Determine sentiment category
    sentiment = "neutral"
    if sentiment_score > 0:
        sentiment = "positive"
    elif sentiment_score < 0:
        sentiment = "negative"

    # Prepare the response
    response = {
        "sentiment": sentiment,
        "score": sentiment_score
    }

    return {
        "statusCode": 200,
        "body": json.dumps(response)
    }
