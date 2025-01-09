import os
import json
import urllib.request
import boto3

def format_crypto_data(crypto):
    name = crypto.get("name", "Unknown")
    symbol = crypto.get("symbol", "Unknown")
    current_price = crypto.get("market_data", {}).get("current_price", {}).get("usd", "Unknown")
    market_cap = crypto.get("market_data", {}).get("market_cap", {}).get("usd", "Unknown")
    total_volume = crypto.get("market_data", {}).get("total_volume", {}).get("usd", "Unknown")

    return (
        f"Cryptocurrency Update for {name} ({symbol}):\n"
        f"Current Price: ${current_price}\n"
        f"Market Cap: ${market_cap}\n"
        f"Total Volume: ${total_volume}\n"
    )

def lambda_handler(event, context):
    # Get environment variables
    sns_topic_arn = os.getenv("SNS_TOPIC_ARN")
    sns_client = boto3.client("sns")

    # Fetch data from the CoinGecko API
    coins_file_path = "./coins.txt"
    with open(coins_file_path, "r") as file:
        crypto_ids = [line.strip() for line in file.readlines()]

    messages = []

    for crypto_id in crypto_ids:
        api_url = f"https://api.coingecko.com/api/v3/coins/{crypto_id}"
        try:
            with urllib.request.urlopen(api_url) as response:
                data = json.loads(response.read().decode())
                message = format_crypto_data(data)
                messages.append(message)
        except Exception as e:
            print(f"Error fetching data for {crypto_id}: {e}")

    for message in messages:
        try:
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Message=message,
                Subject="Cryptocurrency Update"
            )
        except Exception as e:
            print(f"Error publishing message to SNS: {e}")

    return {
        "statusCode": 200,
        "body": json.dumps("Data processed and sent to SNS")
    }