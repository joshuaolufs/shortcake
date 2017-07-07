-- Config Options --
stable = true -- use the stable channel (true) or the development channel (false) for updates
variables = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
hFlipBitOn = false -- changes left and right, h = horizontal
vFlipBitOn = false -- changes up and down, v = vertical
includeUp = false -- break the block above when moving forward with the 'x' command
includeDown = false -- break the block below when moving forward with the 'x' command
printStatus = false -- used for debugging
agressive = true -- whether or not the turtle should attack things blocking its path
softAbort = {"bedrock","Bedrock"} -- don't try to break or move into these blocks
stallOnAbort = false -- if something goes wrong wait for user to fix it
UPDATE_PAUSE = 0.12 -- pause for block update
GRAVITY_PAUSE = 0.5 -- pause for falling blocks
USER_PAUSE = 2 -- time between checks for user input
TIMEOUT = 50 -- how many times it should attempt a command before increasing the pause time
programs = {}
	programs["layer"] = "((x[A-1]>x>i)[B-1])[B>1]x[A-1]"
	programs["stripmine"] = "((x[A-1]>x>i)[B-1])[B>1]x[A-1]((v>>((x[A-1]>x>i)[B-1])[B>1]x[A-1])[C-1])[C>1]"
	programs["simplebranchmine"] = "k',(x[C+1]b<(xBb<<',xB',)2>)A"
	programs["branchmine"] = "',(x[(C+1)*2]<(xBb<',xC',xb<xBb)2>)[math.floor(A/2)](x[C+1]<xBb<<(xBb)2)[A%2]"
	programs["fastmine"] = "(',vd(((x[A-1]>x>i)[B-1])[B>1]x[A-1]v3d>>)[C/3-(C%3)/3-1]((x[A-1]>x>i)[B-1])[B>1]x[A-1]',(vv>>)[C%3~=0])[C>2](,d((x[A-1]>x>i)[B-1])[B>1]x[A-1])[C%3==2](((x[A-1]>x>i)[B-1])[B>1]x[A-1])[C%3==1]"