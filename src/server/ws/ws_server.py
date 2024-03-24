#!/usr/bin/env python3
from __future__ import print_function
from __future__ import division


import asyncio
import datetime
import collections
import websockets
import random
import ssl
import string
import re
import os
import argparse

# from codecs import (utf_8_encode, utf_8_decode,
#                     latin_1_encode, latin_1_decode)

def parse_args():
	parser = argparse.ArgumentParser(description='Hosts a websocket server for AlexGames')
	parser.add_argument('--port', help='Port to use for websocket server', type=int, default=55433)
	parser.add_argument('--use_ssl', help='Whether or not to use SSL. If you use SSL, you must provide ssl_fullchain and ssl_privkey params', action='store_true')
	parser.add_argument('--silence_ssl_warning', help='Set this param to prevent this script from logging several lines about not using SSL', action='store_true')
	parser.add_argument('--ssl_fullchain', help='Path to fullchain.pem SSL cert file on your system.', default='fullchain.pem')
	parser.add_argument('--ssl_privkey',   help='Path to privkey.pem SSL cert file on your system.', default='privkey.pem')

	args = parser.parse_args() 

	return args

def get_logfile_name():
    return "logs/%s.log" % datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")

os.makedirs('logs/', exist_ok=True)
f_log = open(get_logfile_name(), "w")

def log(msg):
    date_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = '%s: %s' % (date_str, msg)
    print(log_entry)
    f_log.write(log_entry + '\n')


class InvalidMessageException(Exception):
    pass

Msg = collections.namedtuple("Msg", field_names = ["dst", "payload"])

sessions = {}
#ws_to_session_id = {}

def generate_session_id():
	return ''.join([ random.choice(string.ascii_lowercase) for _ in range(6) ])

def get_ws_name(ws):
	try:
		addr, port = ws.remote_address
		return '%s:%d' % (addr, port)
	except:
		log("Err getting name from ws.remote_address: %s" % repr(ws.remote_address))
	raise

def to_bin_str(arg):
	return ' '.join([ '%02x' % ord(c) for c in arg ])

def parse_recvd_msg(msg_str):
	m = re.match(r'("([0-9a-zA-Z.:]+)":)(.*)', msg_str, flags=re.DOTALL)
	if m is None:
		log("Error parsing recvd msg: %r" % msg_str)
		raise InvalidMessageException("Invalid message")

        # `dst_wrapped` is only used to determine the length of the header (dst in quotes and a colon)
        # to be removed from msg_str then stored as payload
	dst_wrapped, dst, _ = m.groups()

	payload = msg_str[len(dst_wrapped):]

	return Msg(dst=dst, payload=payload)

async def send_msg(ws, src, payload):
    msg = '"%s":%s' % (src, payload)
    await ws.send(msg)

async def client_left(websocket, session_id, client_name):
	try:
		del sessions[session_id][client_name]
	except KeyError:
		pass

	for name in sessions[session_id]:
		ws = sessions[session_id][name]
		# await ws.send('"ctrl":left:%s' % client_name)
		await send_msg(ws, "ctrl", 'player_left:%s' % client_name)
                # TODO catch websockets.exceptions.ConnectionClosedError here?

async def client_handler(websocket, path):
	our_name = get_ws_name(websocket)
	log('Received connection from %r' % our_name)

	data = await websocket.recv()
	log("Recvd init data %r" % data)

	if data == '"ctrl":new_session':
		session_id = generate_session_id()
		await send_msg(websocket, "ctrl", "connected:%s" % session_id)
	else:
		m = re.match(r'"ctrl":session:\s*([0-9a-zA-Z]*)', data)
		if m is None:
			log('bad session cmd from client: %r' % data)
		session_id, = m.groups()

	if session_id not in sessions:
		sessions[session_id] = {}

	sessions[session_id][our_name] = websocket
	log('Session %r now has %d clients' % (session_id, len(sessions[session_id])))
	#ws_to_session_id[websocket] = session_id


	while True:
		try:
			data = await websocket.recv()
		except (websockets.exceptions.ConnectionClosedOK,
		        websockets.exceptions.ConnectionClosedError) as e:
			log("Client %s disconnected, removing from session %r" % \
			      (our_name, session_id))
			await client_left(websocket, session_id, our_name)
			break
		# log("Recvd msg: %s" % to_bin_str(data))
		try:
		    recvd_msg = parse_recvd_msg(data)
		except InvalidMessageException:
		    log("Invalid recvd msg %r" % data)
		    continue

		msg = '"%s":%s' % ( our_name, recvd_msg.payload )

		if recvd_msg.dst == "all":
		    dsts = sessions[session_id].keys()
		elif recvd_msg.dst in sessions[session_id]:
		    dsts = [recvd_msg.dst]
		else:
		    log("Client %r tried to message %r but it is not present in: %r" %
		          (our_name, recvd_msg.dst, sessions[session_id].keys()))
		    websocket.send("dst_not_found:%s" % recvd_msg.dst)
		    continue

		# TODO should allow it to only send to one player
		# log('Recvd data %r from %s, relaying to sessions %r' % (data, repr(websocket.remote_address), dsts))
		# log("Sending message %s to %s" % (to_bin_str(msg), dsts))
		for client_name in dsts:
			ws = sessions[session_id][client_name]
			if ws == websocket: continue
			try:
				await ws.send(msg)
			except (websockets.exceptions.ConnectionClosedOK,
			        websockets.exceptions.ConnectionClosedError) as e:
				log("Error %s sending to client %s, removing from session %r" %
				      (our_name, repr(ws.remote_address), session_id))
				#try:
				#	sessions[session_id].remove(ws)
				#except KeyError:
				#	pass
				continue
				# break

args = parse_args()

#use_ssl = False

ssl_ctx = None
if args.use_ssl:
	ssl_ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
	#ssl_ctx.load_cert_chain('fullchain.pem', 'privkey.pem')
	ssl_ctx.load_cert_chain(args.ssl_fullchain, args.ssl_privkey)
else:
	if not args.silence_ssl_warning:
		log("""\
Warning: use_ssl is false. This is fine for testing on your local network,
(assuming you aren't worried about someone on your own network man-in-the-
middleing this game) but if you are serving the static HTML over HTTPS,
the websocket connection must be SSL too. (at least on Firefox, I think)

If you still want to try out the game but don't want to
give my script access to your SSL certs, then that's fine, you don't need
a websocket server at all! The games should still work even without a
websocket server. (You can play by yourself or by sharing a device
with a friend, for some games)

Alternatively, you can host your own static HTML, but use my websocket
server, by setting the `ws_server` URL param, i.e. navigating to something
like this (replace "your_site.example.com" with your own site):

    http://your_site.example.com/?ws_server=wss://alexbarry.net:55433

To silence this warning, add the --silence_ssl_warning parameter.
""")

#port = 55433
log('Hosting server on port %d' % args.port)
ws_server = websockets.serve(client_handler, host=None, port=args.port, ssl=ssl_ctx)
loop = asyncio.get_event_loop()
loop.run_until_complete(ws_server)
loop.run_forever()
