# server.py
import os
from livekit import api
from flask import Flask
import string
import random
import yaml

api_key=''
api_secret=''

with open('./config.yaml','r') as f:
    config=yaml.safe_load(f)
    keys=config['keys']
    for k,v in keys.items():
        api_key=k
        api_secret=v
        break

def random_identity()->str:
    s=''
    for i in range(20):
        s+=random.choice(string.ascii_letters)
    return s

app = Flask(__name__)

@app.route('/getToken')
def getToken():
  token = api.AccessToken(api_key,api_secret) \
    .with_identity(random_identity()) \
    .with_name("Jim") \
    .with_grants(api.VideoGrants(
        room_join=True,
        room="my-room",
    ))
  return token.to_jwt()

