import unittest
from main import app, counter

class CounterAppTestCase(unittest.TestCase):
    
    def setUp(self):
        self.app = app.test_client()  # Set up the test client for the Flask app
        self.app.testing = True
        global counter
        counter = 0  # Reset counter before each test

    def tearDown(self):
        pass  

    def test_main_page(self):
        response = self.app.get('/')  # Sending GET request 
        self.assertEqual(response.status_code, 200)  # Checking if status code 200
        self.assertIn(b'Counter Service Application', response.data)  #response data contains 'Counter Service Application'

    def test_increment_counter(self):
        response = self.app.post('/add')  # Sending POST request to the /add URL
        self.assertEqual(response.status_code, 200)  # Checking if 200
        self.assertIn(b'Counter value: 1', response.data)  #counter value is 1

    def test_subtract_counter(self):
        global counter
        counter = 1  # Set counter to 1 
        response = self.app.post('/subtract')  # Sending POST request
        self.assertEqual(response.status_code, 200)  # Checking if 200
        self.assertIn(b'Counter value: 0', response.data)  # Checking if the counter is 0

if __name__ == '__main__':
    unittest.main()
    
