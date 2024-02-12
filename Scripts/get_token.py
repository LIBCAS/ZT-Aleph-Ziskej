#!/usr/bin/env python3

import datetime

import jwt # pip install pyjwt

app_id = 'aba007'


shared_secret = '1d775c98-a91f-4ead-aaff-3231abbe425f' #ostra

now = datetime.datetime.utcnow()

token_dict = dict(

iss = app_id,
iat = now,
exp = now + datetime.timedelta(seconds=3600),
app = app_id,
)
                
token = jwt.encode(token_dict, shared_secret, algorithm='HS256')
print(token)