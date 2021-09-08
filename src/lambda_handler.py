from django_lambda_example.wsgi import application
from apig_wsgi import make_lambda_handler

handler = make_lambda_handler(application)
