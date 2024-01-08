from fastapi import FastAPI, Response, HTTPException, status, Request, Form
from fastapi.responses import JSONResponse
from bson.objectid import ObjectId
from pymongo import ASCENDING, DESCENDING, IndexModel
import boto3
from motor.motor_asyncio import AsyncIOMotorClient
import uvicorn
import time
import os
import asyncio


from cachetools import TTLCache

# Create an in-memory cache with a maximum size and expiration time
cache = TTLCache(maxsize=100, ttl=600)  # Adjust the size and TTL values as per your needs


# Set up AWS credentials
ACCESS_KEY = 'AKIA5G3JW2D5KGDK2GA2'
SECRET_KEY = 'sneFezNX7mLg+l/HL3cfwwFQSrAFGxquxcXO2ycG'

# Authorize access to s3 client with keys
s3_client = boto3.client('s3', aws_access_key_id=ACCESS_KEY,
                         aws_secret_access_key=SECRET_KEY)
bucket_name = 'swappify-images'

# Connect to mongo instance
client = AsyncIOMotorClient('mongodb://localhost:27017')
db = client['Swappify']
# Extracting collections for later use
items = db['Items']
users = db['Users']
trades = db['Trades']
accepted = db['Accepted']
declined = db['Declined']

async def create_indexes():
    # Define indexes
    await db.users.create_index([('google_id', ASCENDING)], unique=True)

# Call the function to create indexes when the application starts up
async def startup():
    await create_indexes()

# Create FastAPI instance
app = FastAPI(on_startup=[startup])


# Endpoint for handling likes and dislikes regarding an item
@app.get('/login')
async def login(request: Request):
    """
    @brief Handles when a user tries to login
    @param request: The request object containing the users google_id
    @return: A JSON response indicating success or failure
    """
    # Extracts userId from whats after '?' in the url submitted by user
    user_id = request.query_params.get('userId')
    user = await users.find_one({'google_id': user_id})
    # If no user could be found
    if user is None:
        return JSONResponse(content={'status': 'missing', 'recently_matched': []})
    if len(user['recently_matched']) <= 0:
        return JSONResponse(content={'status': 'OK', 'recently_matched': []})

    return JSONResponse(content={'status': 'OK', 'recently_matched': [1, 2, 3]})


# Endpoint for adding a user to the system
@app.post('/add-user')
async def add_user(request: Request):
    """
    @brief Adds a user to the database
    @param request: The request object containing the user data
    @return: A JSON response indicating success or failure
    """
    user_data = await request.json()
    user_data['liked_users'] = []
    user_data['liked'] = []
    user_data['disliked'] = []
    user_data['owned'] = []
    user_data['matched'] = []
    user_data['recently_matched'] = []
    user_data['recieved_trades'] = []
    user_data['sent_trades'] = []

    result = await users.insert_one(user_data)
    if result.inserted_id:
        return f"User with ID {result.inserted_id} has been added to the database"
    else:
        return "Failed to add user to the database"


async def clear_recent_matches(user_id):
    '''
    @brief Clears the recently matched list for a user
    @param user_id: The id of the user to clear the list for
    '''
    await users.update_one({"google_id": user_id}, {'$set': {'recently_matched': []}})

    
async def next_item_to_view(user, filters):
    '''
    @brief Finds the next item that the user hasn't liked, disliked or owns
    @param user: The user to find the next item for
    @return: The next item to view
    '''
    # Generate a cache key based on user and filters
    cache_key = f"{user['_id']}_{filters}"

    # Check if the items are already in the cache
    if cache_key in cache:
        item_data_list = cache[cache_key]
    else:
        liked = user['liked']
        disliked = user['disliked']
        owned = user['owned']
        seen_items = liked + disliked + owned

        if len(filters) == 0:
            # Get all items that the user hasn't liked, disliked, or owns
            item_data_list = await items.find({'_id': {'$nin': seen_items}}).to_list(length=100)
        else:
            tags = filters.split(',')
            item_data_list = await items.find({'_id': {'$nin': seen_items}, 'tags': {'$in': tags}}).to_list(length=100)

    if len(item_data_list) == 0:
        return None
    
    item_data = item_data_list.pop(0)
    # Cache the items
    if len(item_data_list) > 0:
        cache[cache_key] = item_data_list
    else:
        cache.pop(cache_key, None)

    return item_data



@app.get('/get-item-id')
async def get_item_id(request: Request):
    """
    @brief Sends data regarding an item to the client
    @param request: The request object containing the itemId
    @return: A JSON response containing the item data
    """
    item_id = request.query_params.get('itemId')
    print("item_id = " + str(item_id))

    objInstance = ObjectId(item_id)

    item = await items.find_one({'_id': objInstance})

    if item == None:
        return "error" #TODO 

    item['_id'] = str(item['_id'])

    return item


@app.get('/get-item-data')
async def get_item_data(request: Request):
    """
    @brief Sends data regarding an item to the client
    @param request: The request object containing the users google_id
    @return: A JSON response containing the item data
    """
    # Extracts userId from whats after '?' in the url submitted by user
    user_id = request.query_params.get('userId')
    user = await users.find_one({'google_id': user_id})

    filters = request.query_params.get('filters')
    print("filters" + str(filters))

    # If no user could be found
    if user == None:
        return JSONResponse(content={'status': 'error', 'message': 'User not found'})

    # TODO is this at the wrong place? should it really be in get-item-data? Clear recent matches
    await clear_recent_matches(user_id)

    item_data = await next_item_to_view(user,filters)

    # If no item could be found
    if item_data == None:
        return JSONResponse(content={'status': 'error', 'message': 'Out of items'})

    # Defining what to send
    to_send = {
        "item_id": str(item_data['_id']),
        "name": item_data['name'],
        "desc": item_data['desc'],
        "gender": item_data['gender'],
        "type": item_data['type'],
        "size": item_data['size'],
        "tags": item_data['tags'],
        "images": item_data['images'],
        "status": 'OK'
    }

    # Convert to json format to send
    return JSONResponse(content=to_send)


async def upload_images_to_s3(images):
    '''
    @brief Uploads images to S3 and returns the urls
    @param images: The images to upload
    @return: A list of urls to the uploaded images
    '''
    current_time = str(int(time.time()))
    extraoffset = 0
    urls = []
    for image in images:
        filnamntest = current_time + str(extraoffset) + ".jpeg"
        s3_client.put_object(Bucket=bucket_name, Key=filnamntest, Body=bytes(
            image), ContentType="image/jpeg")
        urls.append(
            f'https://{bucket_name}.s3.eu-north-1.amazonaws.com/{filnamntest}')
        extraoffset += 1
    return urls


@app.post('/add-item')
async def add_item(request: Request):
    """
    @brief Adds an item to the database and uploads images to S3
    @param request: The request object containing the item data
    @return: A JSON response indicating success or failure
    """

    # Get the item data from the request
    item_data = await request.json()

    # Upload images to S3 and get the urls
    urls = await upload_images_to_s3(item_data['images'])

    # Add the urls to the item data
    item_data['images'] = urls

    # Insert the item into the database
    item = await items.insert_one(item_data)

    # Update owned field in items to not show it for yourself
    await users.update_one({'google_id': item_data['user_id']}, {'$push': {'owned': item.inserted_id}})

    # Return a JSON response indicating success
    return {'status': 'success'}


async def check_match(item_user, user_id):
    '''
    @brief Checks if the user has liked the item_user
    @param item_user: The user that owns the item
    @param user_id: The id of the user that liked the item
    @return: True if the user has liked the item_user, False otherwise
    '''
    if item_user == None:
        return False

    liked_list = item_user['liked_users']
    if user_id in liked_list:
        return True
    else:
        return False


async def get_all_user_items_that_item_user_liked(item_user_id, user_id):
    '''
    @brief Gets all of the items that the user owns that the item_user has liked
    @param item_user_id: The id of the user that owns the item
    @param user_id: The id of the user that liked the item
    @return: A list of all of the items that the user owns that the item_user has liked
    '''
    user = await users.find_one({'google_id': user_id})
    all_user_items = user['owned']
    all_matched_items = []
    for item_id in all_user_items:
        if item_id in item_user_id['liked']:
            all_matched_items.append(item_id)
    return all_matched_items


async def update_matches_in_db(item_id, item_user, user_id, return_val):
    '''
    @brief Updates the matches in the database
    @param item_id: The id of the item that the user liked
    @param item_user: The user that owns the item
    @param user_id: The id of the user that liked the item
    @param return_val: The value returned from check_match
    '''
    if return_val == True:
        
        item_id = str(item_id)  # convert ObjectId to string
        all_matched_items = await get_all_user_items_that_item_user_liked(item_user, user_id)

        # Update the matched field for the user that liked the item
        already_matched = await users.find_one({'google_id': user_id, 'matched.google_id': item_user['google_id']})
        if already_matched: # TODO maybe use Bulk Writes?
            await users.update_one({'google_id': user_id, 'matched.google_id': item_user['google_id']}, {'$addToSet': {'matched.$.item_ids': item_id}})
            await users.update_one({'google_id': item_user['google_id'], 'matched.google_id': user_id}, {'$addToSet': {'matched.$.item_ids': all_matched_items}, '$addToSet': {'recently_matched': {'google_id': user_id, 'item_ids': all_matched_items}}})
        else:
            await users.update_one({'google_id': user_id}, {'$push': {'matched': {'google_id': item_user['google_id'], 'item_ids': [item_id]}}})
            await users.update_one({'google_id': item_user['google_id']}, {'$push': {'matched': {'google_id': user_id, 'item_ids': all_matched_items}, 'recently_matched': {'google_id': user_id, 'item_ids': all_matched_items}}})




# Function for updating the liked and disliked lists
async def update_likes(feedback, user_id, item_id):
    """
    @brief Updates the liked and disliked lists
    @param feedback: The feedback given by the user, either 'like' or 'dislike'
    @param user_id: The id of the user who gave the feedback
    @param item_id: The id of the item that the user gave feedback on
    @return: A boolean indicating whether the it resulted in a match or not
    """
    item = await items.find_one({'_id': item_id})
    if item == None:
        return False
    item_owner_id = item['user_id']
    item_user = await users.find_one({'google_id': item_owner_id})
    if item_user == None:
        return False

    return_val = False
    if feedback == 'like':
        if item_user == None or item['user_id'] in item_user['liked_users']:
            update_users = {'$push': {'liked': item_id}}
        else:
            update_users = {'$addToSet': {
                'liked': item_id, 'liked_users': item['user_id']}}

        # Check if there is a match
        return_val = await check_match(item_user, user_id)
        await update_matches_in_db(item_id, item_user, user_id, return_val)
    else:
        update_users = {'$push': {'disliked': ObjectId(item_id)}}

     # Define the filter
    filter_users = {'google_id': user_id}
    # Update the database entry
    await users.update_one(filter_users, update_users)
    return return_val


@app.post('/item-feedback')
async def item_feedback(request: Request):
    """
    @brief Handles when a user gives feedback on an item
    @param request: The request object containing the feedback data
    @return: A JSON response indicating success or failure
    """
    # Get the user data from the request
    user_data = await request.json()

    # Extract relevant data from user_data
    choice = user_data['feedback']
    item_id = ObjectId(user_data['item_id'])
    user_id = user_data['user_id']
    # Updates database
    if (await update_likes(choice, user_id, item_id)):
        return JSONResponse(content={'match': 'true'})
    else:
        return JSONResponse(content={'match': 'false'})


@app.post('/add-trade')
async def add_trade(request: Request):
    """
    @brief Handles when a new trade offer is recieved
    @param request: The request object containing the trade
    @return: A JSON response indicating success or failure
    """
    user_data = await request.json()
    user_data['status'] = "pending"

    insertinfo = await trades.insert_one(user_data)
    insid = insertinfo.inserted_id

    # get the userId from the data
    senderId = user_data['senderId']
    recieverId = user_data['recieverId']
    # Add the trade id to the senders sent offers
    # NOTE MIGHT BE REDUNDANT
    await users.update_one({'google_id': senderId}, {'$push': {'sent_trades': ObjectId(insid)}})
    # Add the trade to the recievers recieved offers
    await users.update_one({'google_id': recieverId}, {'$push': {'recieved_trades': ObjectId(insid)}})

    return {'status': 'OK'}


@app.get('/get-accepted-trades')
async def get_accepted_trades(request: Request):
    """
    @brief Handles fetching accepted trades
    @param request: The userId
    @return: A JSON response containing all the users accepted trades
    """
    user_id = request.query_params.get('userId')
    user_info = await users.find_one({'google_id': user_id})
    # Plocka accepted trades
    alltrades = []

    for trade in user_info['accepted_trades']:
        accepted_trade = await accepted.find_one({'_id': trade})
        accepted_trade['_id'] = str(accepted_trade['_id'])
        alltrades.append(accepted_trade)
    print(str(alltrades))
    return {'accepted': alltrades}


@app.get('/get-declined-trades')
async def get_declined_trades(request: Request):
    """
    @brief Handles fetching declined trades
    @param request: The userId
    @return: A JSON response containing all the users declined trades
    """
    user_id = request.query_params.get('userId')
    user_info = await users.find_one({'google_id': user_id})
    # Plocka accepted trades
    alltrades = []

    for trade in user_info['declined_trades']:
        accepted_trade = await declined.find_one({'_id': trade})
        accepted_trade['_id'] = str(accepted_trade['_id'])
        alltrades.append(accepted_trade)
    print(str(alltrades))
    return {'accepted': alltrades}


@app.get('/get-trades')
async def get_trades(request: Request):
    """
    @brief Handles when a new trade offer is recieved
    @param request: The request object containing the trade
    @return: A JSON response indicating success or failure
    """
    user_id = request.query_params.get('userId')
    # get all users recieved trades and return them
    # Add the trade id to the senders sent offers
    # NOTE MIGHT BE REDUNDANT ObjectId
    userdata = await users.find_one({'google_id': user_id})
    recieved_trades = []

    for id in userdata['recieved_trades']:
        recieved_trades.append(str(id))

    return {'status': 'OK', 'trades': recieved_trades}


@app.get('/get-trade')
async def get_trade(request: Request):
    """
    @brief Gets a trade offer based on its id
    @param get: The id
    @return: The trade
    """
    trade_id = request.query_params.get('tradeId')

    objInstance = ObjectId(trade_id)

    thetrade = await trades.find_one({'_id': objInstance})

    if thetrade != None:
        thetrade['_id'] = str(thetrade['_id'])
        # Get return the trading info
        return thetrade
    return "no good"


@app.post('/decline-trade')
async def decline_trade(request: Request):

    trade_info = await request.json()
    trade_id = trade_info['tradeId']

    # Insert the item data into the item collection
    await trades.update_one({'_id': ObjectId(trade_id)}, {'$set': {'status': 'declined'}})

    trade_info = await trades.find_one({'_id': ObjectId(trade_id)})
    print(trade_info)
    await users.update_one({'google_id': trade_info['senderId']}, {'$pull': {'sent_trades': ObjectId(trade_id)}})
    await users.update_one({'google_id': trade_info['recieverId']}, {'$pull': {'recieved_trades': ObjectId(trade_id)}})
    # Remove from old trade db
    deleted = await trades.find_one_and_delete({'_id': ObjectId(trade_id)})
    # Add to db of declined trades

    newid = await declined.insert_one({
        "senderId": deleted['senderId'],
                "recieverId": deleted['recieverId'],
                "senderoffer": deleted['senderoffer'],
                "recieverdemands": deleted['recieverdemands']
        })
    print("Added declined trade " + str(await declined.find_one({'_id': newid.inserted_id})))
    # Add to the senders array of declined trades
    await users.update_one({'google_id': trade_info['senderId']}, {'$push': {'declined_trades': newid.inserted_id}})
    await users.update_one({'google_id': trade_info['recieverId']}, {'$push': {'declined_trades': newid.inserted_id}})

    return {'status': 'OK'}


@app.post('/accept-trade')
async def accept_trade(request: Request):
    trade_info = await request.json()
    trade_id = trade_info['tradeId']

    # Insert the item data into the item collection
    result = await trades.update_one({'_id': ObjectId(trade_id)}, {'$set': {'status': 'accepted'}})

    print(trade_id)
    trade_info = await trades.find_one({'_id': ObjectId(trade_id)})
    print(trade_info)

    await users.update_one({'google_id': trade_info['senderId']}, {'$pull': {'sent_trades': ObjectId(trade_id)}})
    await users.update_one({'google_id': trade_info['recieverId']}, {'$pull': {'recieved_trades': ObjectId(trade_id)}})
    # Remove from old trade db
    deleted = await trades.find_one_and_delete({'_id': ObjectId(trade_id)})
    # Add to db of finished trades
    newid = await accepted.insert_one({
        "senderId": deleted['senderId'],
                "recieverId": deleted['recieverId'],
                "senderoffer": deleted['senderoffer'],
                "recieverdemands": deleted['recieverdemands']
        })
    print("Added accepted trade " + str(await accepted.find_one({'_id': newid.inserted_id})))
    # Add to boths array of finished trades
    await users.update_one({'google_id': trade_info['senderId']}, {'$push': {'accepted_trades': newid.inserted_id}})
    await users.update_one({'google_id': trade_info['recieverId']}, {'$push': {'accepted_trades': newid.inserted_id}})


    return {'status': 'OK'}


@app.get('/get-matches')
async def get_matches(request: Request):
    """
    @brief Returns a list of the user's matches
    @param request: The request object containing the user's id
    @return: A JSON response containing the matches
    """
    user_id = request.query_params.get('userId')
    user = await users.find_one({'google_id': user_id})
    if user['matched'] == []:
        return {'status': 'no matches'}

    names_and_items = []
    ids = []
    for match in user['matched']:
        google_id = match['google_id']
        # Get the items that the user has liked
        items_list = match['item_ids']
        items_to_send = []
        for i in range(len(items_list)):
            item = await items.find_one({'_id': ObjectId(items_list[i])})
            items_to_send.append(item['images'])  # we only need the image urls

        person = await users.find_one({'google_id': google_id})
        if person:
            person_info = {
                "username": person['username'],
                "phone": person['phone'],
                "items": items_to_send  # we only send the image urls of the items
            }
            ids.append(person['google_id'])
        names_and_items.append(person_info)

    return {'status': 'OK', 'matches': names_and_items, 'ids': ids}


async def get_items(user):
    '''
    @brief Returns a list of the users items
    @param user: The user object
    @return: A list of the users items
    '''
    item_list = []
    if user != None:
        result = await items.find({'user_id': user['google_id']}).to_list(length=None)
        item_list = [doc for doc in result]
        for item in item_list:
            item['_id'] = str(item['_id'])
    return item_list


@app.get('/get-user-items')
async def get_user_items(request: Request):
    """
    @brief Returns a list of the users items
    @param request: The request object containing the users google id
    @return: A JSON response containing the items
    """
    # Extracts userId from whats after '?' in the url submitted by user
    user_id = request.query_params.get('userId')
    user = await users.find_one({'google_id': user_id})

    item_list = await get_items(user)

    # Convert to json format to send
    return JSONResponse({'info': item_list})


@app.get('/get-one-user-item')
async def get_one_user_item(request: Request):
    """
    @brief Returns a single item of a user
    @param request: The request object containing the users google id
    @return: A JSON response containing the items
    """

    # Extracts userId from whats after '?' in the url submitted by user
    user_id = request.query_params.get('userId')

    item_index = request.query_params.get('itemIndex')

    print("item index " + item_index)

    item_index = int(item_index)

    user = await users.find_one({'google_id': user_id})
    if user != None:
        # This code is pretty much ass. Instead of finding item by index we could just do so by object id but whatever.
        result = await items.find({'user_id': user_id}).to_list(length=None)
        item_list = [doc for doc in result]
        # Pretty poor from a defensive perspective. But I suppose this always works.
        item = item_list[item_index]
        item['_id'] = str(item['_id'])

    # Convert to json format to send
    # return JSONResponse({'info': {'item': item, 'tags': item['tags']}})

    return JSONResponse({'info': item})


@app.post('/edit-user')
async def edit_user(request: Request):
    """
    @brief Edits the users phone number
    @param request: The request object containing the users google id and new phone number
    @return: A JSON response indicating success or failure
    """
    # Get the user data from the request
    user_id = request.query_params.get('userId')
    user_data = await request.json()

    # Insert the user data into the users collection
    await users.update_one({'google_id': user_id}, {'$set': {'phone': user_data['phone']}})

    return {"status": "Success"}


# Updates the text fields regarding a specific item
@app.post('/edit-item')
async def edit_item(request: Request):
    """
    @brief Edits the item text-fields
    @param request: The request object containing the users google id and new phone number
    @return: A JSON response indicating success or failure
    """
    # Get the user data from the request
    user_id = request.query_params.get('userId')
    item_data = await request.json()

    # Insert the item data into the item collection
    result = await items.update_one({'_id': ObjectId(item_data['item_id'])}, {'$set': {'name': item_data['name'],
                                                                                       'desc': item_data['desc'],
                                                                                       'gender': item_data['gender'],
                                                                                       'size': item_data['size'],
                                                                                       'tags': item_data['tags'],
                                                                                       }})

    return "Success"


@app.post('/delete-one-pic')
async def delete_one_pic(request: Request):
    """
    @brief Removes a picture from an article
    @param request: The request object containing the item data, objectID of the article and url of the pic to be removed.
    @return: A JSON response indicating success or failure
    """

    # Get the item data from the request
    item_data = await request.json()

    print(item_data['objectIdentifier'])
    # Update images field in items to remove it from the database.
    await items.update_one({'_id': ObjectId(item_data['objectIdentifier'])}, {'$pull': {'images': item_data['imageURL']}})

    filename = os.path.basename(item_data['imageURL'])
    s3_client.delete_object(Bucket=bucket_name, Key=filename)

    # Return a JSON response indicating success
    return JSONResponse({'status': 'success'})


@app.post('/add-more-pics')
async def add_more_pics(request: Request):
    """
    @brief Adds additional pics to an item in the database
    @param request: The request object containing the item data
    @return: A JSON response indicating success or failure
    """

    # Get the item data from the request
    data = await request.json()

    # Mata in bilderna i bucketen...
    urls = await upload_images_to_s3(data['images'])

    # Update the item in the database (append the new pics)
    for url in urls:
        await items.update_one({'_id': ObjectId(data['objectIdentifier'])}, {'$push': {'images': url}})

    # Return a JSON response indicating success
    return JSONResponse({'status': 'success'})


@app.post('/delete-item')
async def delete_item(request: Request):
    """
    @brief Removes an item
    @param request: The request object containing the item data, objectID.
    @return: A JSON response indicating success or failure
    """

    user_id = request.query_params.get('userId')

    # Get the item data from the request
    item_data = await request.json()

    image_list = item_data['images']
    # Update images field in items to remove it from the database.
    for url in image_list:
        filename = os.path.basename(url)
        s3_client.delete_object(Bucket=bucket_name, Key=filename)

    await items.delete_one({'_id': ObjectId(item_data['item_id'])})
    await users.update_one({'google_id': user_id}, {'$pull': {'owned': ObjectId(item_data['item_id'])}})

    # Return a JSON response indicating success
    return JSONResponse({'status': 'success'})

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=5000, ssl_certfile='cert.pem', ssl_keyfile='key.pem')

