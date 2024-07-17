from flask import Flask, render_template, request, jsonify
import time
import uuid
from datetime import datetime

app = Flask(__name__)

# Store chat messages and their timestamps
chat_messages = []

@app.route('/')
def index():
    return render_template('index.html', messages=chat_messages)

@app.route('/send', methods=['POST'])
def send_message():
    message = request.form.get('message')
    ip_address = request.remote_addr  # Get the IP address of the client
    timestamp_sent = time.time()  # Record the timestamp when the message is sent
    message_id = uuid.uuid4().hex  # Generate a unique ID for the message
    chat_messages.append({'id': message_id, 'ip': ip_address, 'text': message, 'sent_time': timestamp_sent})
    return message_id, 204

@app.route('/receive', methods=['POST'])
def receive_message():
    message_id = request.form.get('id')  # Get the message from the form data
    ip_address = request.remote_addr  # Get the IP address of the client
    timestamp_received = time.time()  # Record the timestamp when the message is received
    print("received" + message_id)
    for msg in chat_messages:
        print("checking...")
        if msg['id'] == message_id:
            print("found" + message_id)
            latency_seconds = timestamp_received - msg['sent_time']
            latency_milliseconds = round(latency_seconds * 1000, 2)  # Convert to milliseconds and round to 2 decimal places
            msg['latency'] = latency_milliseconds
            msg['received_time'] = datetime.fromtimestamp(timestamp_received).strftime('%Y-%m-%d %H:%M:%S')
            msg['ip'] = ip_address
            return jsonify(msg),200
            break
    return '', 204

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)