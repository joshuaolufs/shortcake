-- Config Options --
variables = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
hFlipBitOn = false -- changes left and right, h = horizontal
vFlipBitOn = false -- changes up and down, v = vertical
includeUp = false -- break the block above when moving forward with the 'x' command
includeDown = false -- break the block below when moving forward with the 'x' command
printStatus = true -- used for debugging
agressive = true -- whether or not the turtle should attack things blocking its path
softAbort = {"bedrock","Bedrock"} -- don't try to break or move into these blocks
stallOnAbort = false -- if something goes wrong wait for user to fix it
UPDATE_PAUSE = 0.12 -- pause for block update
GRAVITY_PAUSE = 0.5 -- pause for falling blocks
USER_PAUSE = 2 -- time between checks for user input
TIMEOUT = 50 -- how many times it should attempt a command before increasing the pause time