import os
import json
import urllib.request
import boto3

def format_crypto_data(crypto):
    # Extract cryptocurrency details from the API response
    name = crypto.get("name", "Unknown")
    symbol = crypto.get("symbol", "Unknown")
    current_price = crypto.get("market_data", {}).get("current_price", {}).get("usd", "Unknown")
    market_cap = crypto.get("market_data", {}).get("market_cap", {}).get("usd", "Unknown")
    total_volume = crypto.get("market_data", {}).get("total_volume", {}).get("usd", "Unknown")

    # Format the extracted data into a readable message
    return (
        f"Cryptocurrency Update for {name} ({symbol}):\n"
        f"Current Price: ${current_price}\n"
        f"Market Cap: ${market_cap}\n"
        f"Total Volume: ${total_volume}\n"
    )

def lambda_handler(event, context):
    # Get the SNS topic ARN from environment variables
    sns_topic_arn = os.getenv("SNS_TOPIC_ARN")
    # Initialize the SNS client
    sns_client = boto3.client("sns")

    # Path to the file containing cryptocurrency IDs
    coins_file_path = "./coins.txt"
    # Read the cryptocurrency IDs from the file
    with open(coins_file_path, "r") as file:
        crypto_ids = [line.strip() for line in file.readlines()]

    # List to store formatted messages
    messages = []

    # Fetch data for each cryptocurrency ID
    for crypto_id in crypto_ids:
        api_url = f"https://api.coingecko.com/api/v3/coins/{crypto_id}"
        try:
            # Make a request to the CoinGecko API
            with urllib.request.urlopen(api_url) as response:
                # Parse the JSON response
                data = json.loads(response.read().decode())
                # Format the data into a readable message
                message = format_crypto_data(data)
                # Add the message to the list
                messages.append(message)
        except Exception as e:
            # Print an error message if the API request fails
            print(f"Error fetching data for {crypto_id}: {e}")

    # Publish each message to the SNS topic
    for message in messages:
        try:
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Message=message,
                Subject="Cryptocurrency Update"
            )
        except Exception as e:
            # Print an error message if publishing to SNS fails
            print(f"Error publishing message to SNS: {e}")

    # Return a success response
    return {
        "statusCode": 200,
        "body": json.dumps("Data processed and sent to SNS")
    }