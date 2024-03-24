# Before building the android app

Need to run this script to copy some assets from `src/lua_scripts/` to the assets directory:

    src/android/cp_games_assets.sh

... until I figure out how to get gradle to do it.

# Port forwarding to Android emulator

When running the app on an Android emulator, at least on my system, the server
wasn't easily accessible from my local network, or even from the same computer.

Run these commands to forward connections from the computer running the emulator
to the emulator itself: 

	# `adb forward port1 port2`
	# forwards connections to your computer on port1
	# to your emulator on port2.

	# This is the default HTTP port used by the AlexGames android app
	adb forward tcp:55080 tcp:55080

	# This is the default WS   port used by the AlexGames Android app
	adb forward tcp:55433 tcp:55433

Now you should be able to access the server on your emulator by visiting http://localhost:55080 in a browser.

Alternatively, others on your network should be able to visit the server by entering your computer's local IP followed by the port (default is 55080).

## Disable emulator port forwarding

And to undo the above:

	adb forward --remove tcp:55080
	adb forward --remove tcp:55433

Or:

	adb forward --remove-all
