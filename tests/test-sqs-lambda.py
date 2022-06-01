#!/usr/bin/env python3

import logging
import sys

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)
sqs = boto3.resource('sqs')


def send_messages(queue, messages):
    """
    Send a batch of messages in a single request to an SQS queue.
    This request may return overall success even when some messages were not
    sent.
    The caller must inspect the Successful and Failed lists in the response and
    resend any failed messages.

    :param queue: The queue to receive the messages.
    :param messages: The messages to send to the queue. These are simplified to
                     contain only the message body and attributes.
    :return: The response from SQS that contains the list of successful and
             failed
             messages.
    """
    try:
        entries = [{
            'Id': str(ind),
            'MessageBody': msg['body'],
            'MessageAttributes': msg['attributes']
        } for ind, msg in enumerate(messages)]
        response = queue.send_messages(Entries=entries)
        if 'Successful' in response:
            for msg_meta in response['Successful']:
                logger.info(
                    "Message sent: %s: %s",
                    msg_meta['MessageId'],
                    messages[int(msg_meta['Id'])]['body']
                )
        if 'Failed' in response:
            for msg_meta in response['Failed']:
                logger.warning(
                    "Failed to send: %s: %s",
                    msg_meta['MessageId'],
                    messages[int(msg_meta['Id'])]['body']
                )
    except ClientError as error:
        logger.exception("Send messages failed to queue: %s", queue)
        raise error
    else:
        return response


def get_queues(prefix=None):
    """
    Gets a list of SQS queues. When a prefix is specified, only queues with
    names that start with the prefix are returned.

    :param prefix: The prefix used to restrict the list of returned queues.
    :return: A list of Queue objects.
    """
    if prefix:
        queue_iter = sqs.queues.filter(QueueNamePrefix=prefix)
    else:
        queue_iter = sqs.queues.all()
    queues = list(queue_iter)
    if queues:
        logger.info("Got queues: %s", ', '.join([q.url for q in queues]))
    else:
        logger.warning("No queues found.")
    return queues


def test_sqs_lambda():
    """
    Shows how to:
    * Read the lines from this Python file and send the lines in
      batches of 10 as messages to a queue.
    * Receive the messages in batches until the queue is empty.
    * Reassemble the lines of the file and verify they match the original file.
    """
    def pack_message(msg_path, msg_body, msg_line):
        return {
            'body': msg_body,
            'attributes': {
                'path': {'StringValue': msg_path, 'DataType': 'String'},
                'line': {'StringValue': str(msg_line), 'DataType': 'String'}
            }
        }

    def unpack_message(msg):
        return (msg.message_attributes['path']['StringValue'],
                msg.body,
                int(msg.message_attributes['line']['StringValue']))

    queue = get_queues(prefix='lambda_queue')[0]

    with open(__file__) as file:
        lines = file.readlines()

    line = 0
    batch_size = 10
    print(f"Sending file lines in batches of {batch_size} as messages.")
    while line < len(lines):
        messages = [
            pack_message(__file__, lines[index], index)
            for index in range(line, min(line + batch_size, len(lines)))
        ]
        line = line + batch_size
        send_messages(queue, messages)
        print('.', end='')
        sys.stdout.flush()
    print(f"Done. Sent {len(lines) - 1} messages.")


if __name__ == '__main__':
    test_sqs_lambda()
