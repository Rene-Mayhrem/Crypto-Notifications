# NBA Game Notifications Alert System 

This project is an AWS Notification System that uses AWS Lambda and an external API to fetch NBA game data and send notifications via Amazon SNS.

## Table of Contents

- [NBA Game Notifications Alert System](#nba-game-notifications-alert-system)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Architecture Diagram](#architecture-diagram)
  - [Setup](#setup)
  - [Lambda Function](#lambda-function)
  - [License](#license)

## Overview 

The NBA Game Notifications Alert System fetches NBA game data from an external API and sends notifications about the games' status, scores, and other details via Amazon SNS.

## Architecture Diagram
![Architecture Diagram](img/architecture.drawio)

## Setup

1. **Clone the repository:**
    ```sh
    git clone <repository-url>
    cd Game-Notification-with-AWS-Lambda-Amazon-SNS-and-AmazonBridge
    ```

2. **Create SNS Topic and Subscriber:**
    - In AWS, go to SNS and create a new topic named `gd_topic`.
    - Create a new subscription, choose email as the protocol, and select the ARN of the `gd_topic`.

3. **Create IAM Policy and Role:**
    - In AWS, go to IAM and create a new policy with the following permissions:
        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": "sns:Publish",
                  "Resource": "arn:aws:sns:REGION:ACCOUNT_ID:TOPIC"
              }
          ]
        }
        ```
    - Create a new role, select AWS Services, and assign the following policies:
        - The SNS publish policy created above.
        - Lambda Basic Execution Role.
    - Name the role and create it.

4. **Create Lambda Function:**
    - In AWS Lambda, create a new function from scratch.
    - Enter a function name and assign the previously created role.
    - Copy the code from `src/lambda_function.py` into the function.
    - Add the following environment variables:
        ```txt
        NBA_API_KEY=Your_API_Key
        SNS_TOPIC_ARN=Your_SNS_Topic_ARN
        ```
    - Create the function.

5. **Deploy and Test Your Lambda Function:**
    - Open the Lambda function and create a new test event.
    - Run the function and check the logs in CloudWatch for any errors.

## Lambda Function

The main logic of the project is implemented in the `lambda_function.py` file located in the [src](http://_vscodecontentref_/1) directory. Here is a brief overview of the key components:

- **Imports:**
    ```python
    import os
    import json
    import urllib.request
    import boto3
    from datetime import datetime, timedelta, timezone
    ```

- **Function to Format Game Data:**
    ```python
    def format_game_data(game):
        # Get environment variables
      api_key = os.getenv("NBA_API_KEY")
      sns_topic_arn = os.getenv("SNS_TOPIC_ARN")
      sns_client = boto3.client("sns")
      
      # Adjust for Central Time (UTC-6)
      utc_now = datetime.now(timezone.utc)
      central_time = utc_now - timedelta(hours=6)  # Central Time is UTC-6
      today_date = central_time.strftime("%Y-%m-%d")
      
      print(f"Fetching games for date: {today_date}")
      
      # Fetch data from the API
      api_url = f"https://api.sportsdata.io/v3/nba/scores/json/GamesByDate/{today_date}?key={api_key}"
      print(today_date)
      
      try:
          with urllib.request.urlopen(api_url) as response:
              data = json.loads(response.read().decode())
              print(json.dumps(data, indent=4))  # Debugging: log the raw data
      except Exception as e:
          print(f"Error fetching data from API: {e}")
          return {"statusCode": 500, "body": "Error fetching data"}
      
      # Include all games (final, in-progress, and scheduled)
      messages = [format_game_data(game) for game in data]
      final_message = "\n---\n".join(messages) if messages else "No games available for today."
      
      # Publish to SNS
      try:
          sns_client.publish(
              TopicArn=sns_topic_arn,
              Message=final_message,
              Subject="NBA Game Updates"
          )
          print("Message published to SNS successfully.")
      except Exception as e:
          print(f"Error publishing to SNS: {e}")
          return {"statusCode": 500, "body": "Error publishing to SNS"}
      
      return {"statusCode": 200, "body": "Data processed and sent to SNS"}
    ```

- **Lambda Handler Function:**
    ```python
      def lambda_handler(event, context):
        status = game.get("Status", "Unknown")
        away_team = game.get("AwayTeam", "Unknown")
        home_team = game.get("HomeTeam", "Unknown")
        final_score = f"{game.get('AwayTeamScore', 'N/A')}-{game.get('HomeTeamScore', 'N/A')}"
        start_time = game.get("DateTime", "Unknown")
        channel = game.get("Channel", "Unknown")
        
        # Format quarters
        quarters = game.get("Quarters", [])
        quarter_scores = ', '.join([f"Q{q['Number']}: {q.get('AwayScore', 'N/A')}-{q.get('HomeScore', 'N/A')}" for q in quarters])
        
        if status == "Final":
            return (
                f"Game Status: {status}\n"
                f"{away_team} vs {home_team}\n"
                f"Final Score: {final_score}\n"
                f"Start Time: {start_time}\n"
                f"Channel: {channel}\n"
                f"Quarter Scores: {quarter_scores}\n"
            )
        elif status == "InProgress":
            last_play = game.get("LastPlay", "N/A")
            return (
                f"Game Status: {status}\n"
                f"{away_team} vs {home_team}\n"
                f"Current Score: {final_score}\n"
                f"Last Play: {last_play}\n"
                f"Channel: {channel}\n"
            )
        elif status == "Scheduled":
            return (
                f"Game Status: {status}\n"
                f"{away_team} vs {home_team}\n"
                f"Start Time: {start_time}\n"
                f"Channel: {channel}\n"
            )
        else:
            return (
                f"Game Status: {status}\n"
                f"{away_team} vs {home_team}\n"
                f"Details are unavailable at the moment.\n"
            )
    ```

The `lambda_handler` function performs the following steps:
1. Retrieves environment variables.
2. Adjusts the current time to Central Time (UTC-6).
3. Fetches NBA game data from the external API.
4. Formats the game data.
5. Publishes the formatted data to the specified SNS topic.

## License

This project is licensed under the MIT License. See the [LICENSE](http://_vscodecontentref_/2) file for details.
