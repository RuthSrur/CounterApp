import unittest
from flask import Flask
from main import app  # Import the Flask app from your file

class FlaskAppTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = app.test_client()
        cls.client.testing = True

    def test_main_route(self):
        """Test the main route to ensure it renders home.html"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'<html>', response.data)  # Ensure the response contains HTML
        self.assertIn(b'<body>', response.data)  # Ensure the response contains body tag

    def test_increment_route_post(self):
        """Test the increment route with POST method"""
        response = self.client.post('/increment')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'counter', response.data)  # Ensure the response contains counter

    def test_increment_route_get(self):
        """Test the increment route with GET method"""
        response = self.client.get('/increment')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'counter', response.data)  # Ensure the response contains counter

    @classmethod
    def tearDownClass(cls):
        """Reset global state after tests"""
        global counter
        counter = 0

if __name__ == '__main__':
    unittest.main()
