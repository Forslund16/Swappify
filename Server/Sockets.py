import datetime

from gevent import monkey
monkey.patch_all()
from flask import Flask, request
from flask_socketio import SocketIO, emit, join_room
from pymongo import MongoClient, ASCENDING, ReturnDocument
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")


client = MongoClient('mongodb://localhost:27017/')
db = client['Swappify']
chat = db['Chat']

# This is used connect to the socket
@socketio.on('connect')
def handle_connect():
    print('Client connected')

# this is used to join a room
# the room is the id of the chat which is both users google id's combined "google_id1_google_id2"
# the room is sent from the client side
# the room is used to send messages to the correct chat
# the room is also used to get the messages from the database
@socketio.on('join')
def handle_join(room):
    join_room(room)
    print(f'Client joined room {room}')
     # Load the chat history for the room from the database
    chat_history_cursor = chat.find({'room': room}).sort('timestamp', ASCENDING)

    chat_history = []
    # Convert the cursor to a list
    for message in chat_history_cursor:
        # Convert ObjectId to string
        message['_id'] = str(message['_id'])
        chat_history.append(message)
        
    
    emit('firstMessage', chat_history, room=request.sid)


# this is used to disconnect from the socket
@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

# this is used to receive messages from the client
# the message is then added to the database
# the message is then sent back to the correct chat/room
@socketio.on('message')
def handle_message(data):
    # Add timestamp to the message

    current_time = datetime.datetime.now()
    time_string = current_time.strftime("%Y-%m-%d %H:%M:%S")
    data['timestamp'] = time_string
    data['type'] = 'message'

    # Get the room from the request
    room = data['room']

    # Add the message to the database
    inserted_data = chat.insert_one(data)
    
    # Convert ObjectId to string
    data['_id'] = str(inserted_data.inserted_id)
    sender_id = request.sid
    # Emit the message to all clients in the room, excluding the sender
    emit('message', data, room=room, include_self=False, skip_sid=sender_id)

# this is used to store a trade request in the database to be able to show it in the chat
@socketio.on('tradeRequest')
def handle_tradeRequest(data):
    # Add timestamp to the message

    current_time = datetime.datetime.now()
    time_string = current_time.strftime("%Y-%m-%d %H:%M:%S")
    data['timestamp'] = time_string

    # Get the room from the request
    room = data['room']

    # offeredImages = []
    # demandedImages = []

    # for offeredItem in data['offered']:
    #     for image in offeredItem['images']:
    #         offeredImages.append(image)
    
    # for demandedItem in data['demanded']:
    #     for image in demandedItem['images']:
    #         demandedImages.append(image)

    # data['offered'] = offeredImages
    # data['demanded'] = demandedImages
    data['status'] = 'pending'
    data['type'] = 'tradeRequest'

    # Add the message to the database
    inserted_data = chat.insert_one(data)
    
    # Convert ObjectId to string
    data['_id'] = str(inserted_data.inserted_id)
    # Emit the message to all clients in the room, excluding the sender
    emit('message', data, room=room)


# used to handle the accept trade request
# the trade request is updated in the database
# the trade request is then sent back to the correct chat/room
@socketio.on('acceptTrade')
def handle_acceptTrade(data):
    # find the correct chat message by looking for the tradeId
    message = chat.find_one_and_update({'tradeId': data['tradeId']}, {'$set': {'status': 'accepted', 'message': 'Trade offer (accepted)'}})
    message['_id'] = str(message['_id'])
    # send the updated trade request back to the correct chat/room
    emit('acceptTrade', message, room=data['room'])

# used to handle the decline trade request
# the trade request is updated in the database
# the trade request is then sent back to the correct chat/room
@socketio.on('declineTrade')
def handle_declineTrade(data):
    # find the correct chat message by looking for the tradeId
    message = chat.find_one_and_update(
        {'tradeId': data['tradeId']},
        {'$set': {'status': 'declined', 'message': 'Trade offer (declined)'}},
        return_document=ReturnDocument.AFTER
    )
    message['_id'] = str(message['_id'])
    # send the updated trade request back to the correct chat/room
    emit('declineTrade', message, room=data['room'])


# used to get the chat history from the database
# the chat history is sent back to the client
@socketio.on('getChatHistory')
def handle_getChatHistory(room):
    # Load the chat history for the room from the database
    chat_history_cursor = chat.find({'room': room}).sort('timestamp', ASCENDING)

    chat_history = []
    # Convert the cursor to a list
    for message in chat_history_cursor:
        # Convert ObjectId to string
        message['_id'] = str(message['_id'])
        chat_history.append(message)
        

    
    emit('firstMessage', chat_history, room=request.sid)


# This runs the server
if __name__ == '__main__':
    socketio.run(app, host="0.0.0.0", port=5001)
