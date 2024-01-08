from locust import HttpUser, task, between, events
from pymongo import MongoClient

client = MongoClient('localhost', 27017)

# Choose which DB within mongo instance to use
db = client['Swappify']

# Extracting collections for later use
items = db['Items']
users = db['Users']

# Function to add a item to the database
def add_item(user,google_id):
    # Create a new item
    itemdata = {
        'name': 'Jeans',
        'desc': 'Black jeans in good condition',
        'gender': 'woman',
        'size': 'small',
        'type': 'jeans',
        'tags': [ 'jeans', 'black' ],
        'images': [],
        'user_id': str(google_id),
        'liked_by': [],
    }
    # Add the item to the database
    user.client.post('/add-item', json=itemdata)
    # items.insert_one(itemdata)

# start by letting a user try to log in (this will fail because the user doesn't exist yet)
def login(user,google_id):
    # Send a GET request to the /login endpoint to log in the user
    user.client.get('/login?userId=' + str(google_id))

def add_user(self,google_id):
    self.client.post('/add-user', json={
        'google_id': str(google_id),
        'name': 'Test User 2',
        'email': 'test_user_2@example.com',
        'phone': '0701234567',
    })
    # Verify that the user was added to the database by fetching the user from the database
    user = users.find_one({'google_id': str(google_id)})
    assert user is not None
    assert user['email'] == 'test_user_2@example.com'


# Function to remove the test users from the database
def remove_test_users():
    # Remove the test users from the database
    users.delete_many({})
    items.delete_many({})


# Class that represents a single user
class MyUser(HttpUser):

    # Define a class-level variable to store the next available google_id
    google_id_counter = 0

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.google_id = None
        self.item_id = None
    
    # The on_start event is fired when a Locust user starts to run
    def on_start(self):
        self.client.verify = False
        print("Starting test")
        MyUser.google_id_counter += 1
        self.google_id = MyUser.google_id_counter
        print ("Google ID: " + str(self.google_id))
        login(self,self.google_id)
        add_user(self,self.google_id)
        add_item(self, self.google_id)

    # The on_stop event is fired when a Locust user stops running
    def on_stop(self):
        print("Stopping test")
        remove_test_users()

    # A wait time between requests
    wait_time = between(1, 3)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.google_id = None
        self.item_id = None
    # A task is a method that will be executed by a Locust user
    @task(5)
    def get_item(self):
        filters = ""
        response = self.client.get('/get-item-data?userId=' + str(self.google_id)+'&filters='+filters )
        data = response.json()
        if(data['status'] == 'OK'):
            self.item_id = data['item_id']
        else:
            assert data['status'] == 'error'
    
    @task(5)
    def items_feedback(self):
        response = self.client.post('/item-feedback', json={
            'item_id': self.item_id,
            'feedback': 'like',
            'user_id': self.google_id,
        })
        assert response.status_code == 200
    
    @task(2)
    def get_matches(self):
        response = self.client.get('/get-matches?userId=' + str(self.google_id))
        data = response.json()
        assert data['status'] == 'OK' or data['status'] == 'no matches'
    
    @task(1)
    def get_user_items(self):
        response = self.client.get('/get-user-items')
        #check if the response is valid
        assert response.status_code == 200
    
    @task(1)
    def edit_user(self):
        self.client.post('/edit-user?userId='+str(self.google_id), json={
            'phone': '0701234568',
        })
        user = users.find_one({'google_id': str(self.google_id)})
        assert user['phone'] == '0701234568'


            
