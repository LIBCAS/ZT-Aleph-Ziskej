#!/usr/bin/env python3

import datetime

import jwt # pip install pyjwt

app_id = 'aba007'


shared_secret = '790f7076-bfe1-4eeb-88a7-c0f6e736253c' #test

now = datetime.datetime.utcnow()

token_dict = dict(

iss = app_id,
iat = now,
exp = now + datetime.timedelta(seconds=3600),
app = app_id,
)
                
token = jwt.encode(token_dict, shared_secret, algorithm='HS256')
print(token)