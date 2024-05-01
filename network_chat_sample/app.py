from flask import Flask, render_template, request
import time

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
    chat_messages.append({'ip': ip_address, 'text': message, 'sent_time': timestamp_sent})
    return '', 204

@app.route('/receive', methods=['POST'])
def receive_message():
    message = request.form.get('message')
    ip_address = request.remote_addr  # Get the IP address of the client
    timestamp_received = time.time()  # Record the timestamp when the message is received
    for msg in chat_messages:
        if msg['text'] == message and msg['ip'] == ip_address:
            latency_seconds = timestamp_received - msg['sent_time']
            latency_milliseconds = round(latency_seconds * 1000, 2)  # Convert to milliseconds and round to 2 decimal places
            msg['latency'] = latency_milliseconds
            break
    return '', 204

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)