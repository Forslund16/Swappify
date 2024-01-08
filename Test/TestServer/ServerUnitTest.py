import pytest
import requests

item_id = None

def test_login():
    url = "https://127.0.0.1:5000/login?userId=123"
    response = requests.get(url, verify=False)
    assert response.status_code == 200

def test_add_user():
    url = "https://127.0.0.1:5000/add-user"
    userdata = {
        'google_id': '123',
        'name': 'John Doe',
        'email': 'john.doe@gmail.com',
        'phone': '0701234567',
    }
    response = requests.post(url, json=userdata, verify=False)
    assert response.status_code == 200

def test_add_item():
    url = "https://127.0.0.1:5000/add-item"
    itemdata = {
        'name': 'Jeans',
        'desc': 'Black jeans in good condition',
        'gender': 'woman',
        'size': 'small',
        'type': 'jeans',
        'tags': [ 'jeans', 'black' ],
        'images': [
        ],
        'user_id': '1234',
        'liked_by': [],
    }
    response = requests.post(url, json=itemdata, verify=False)
    assert response.status_code == 200
    assert response.json() == {"status": "success"}

def test_get_item_data():
    filters=""
    url = "https://127.0.0.1:5000/get-item-data?userId=123&filters=" + filters + "&gender="
    response = requests.get(url, verify=False)
    assert response.status_code == 200
    global item_id
    item_id = response.json()['item_id']

def test_item_feedback():
    url = "https://127.0.0.1:5000/item-feedback"
    global item_id
    feedbackdata = {
        'item_id': item_id,
        'user_id': '123',
        'feedback': 'like',
    }
    response = requests.post(url, json=feedbackdata, verify=False)
    assert response.status_code == 200

def test_get_matches():
    url = "https://127.0.0.1:5000/get-matches?userId=123"
    response = requests.get(url, verify=False)
    assert response.status_code == 200

if __name__ == "__main__":
    pytest.main()
