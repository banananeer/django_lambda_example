from django_lambda_example.wsgi import application
from apig_wsgi import make_lambda_handler


def handler(event, context):
    if "requestContext" in event and "http" in event["requestContext"]:
        _handler = make_lambda_handler(application)
        return _handler(event, context)
