#!/usr/bin/env python3

import json

print('Loading function test')


def lambda_handler(event, context) -> str:
    print(f"Received event: {json.dumps(event, indent=2)}")

    print(f"Received {len(event['Records'])} record in a single SQS message")
    for i, record in enumerate(event['Records']):
        print(f"{i:03} -> {record['body']}")

    return None
