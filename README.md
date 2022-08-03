# mt_ShipOS
Control all systems conected to your jumpdrive ship in minetest, 

ShipOS is a script that you place in a luacontroller in Minetest.
Main requirements: Minetest with technic mod and digistuff.
Ship cofiguration: a jumpdrive, 1 luacontroller, 1 touchscreen

ShipOS will allow you to set up and communicate with and read out all the connected systems in your ship.
It is a touchscreen based "Operating system" for ease of navigation and reporting. It will not work without a touchscreen properly attached.

## Install:
Place a new luacontroller and touchscreen and make sure they are connected together and to your jumpdrive.
The touchscreen should be set to the digiline channel "ts" (or you can change that in the code) so click the new touchscreen to set the channel.
Change the users section of the code so that your username is at the first location. Click the luacontroller and paste the script into it and press "execute".
After that, you  should not have to touch the script again unless something goes horribly wrong, or want to upgrade.
You should now be able to use the User Interface (UI) in the touchscreen to start using it. If however you see a blank screen, you might need to check all your digiline connections and channel settings.

Touchscreen channel: "ts"

Jumpdrive channel: "jumpdrive"
