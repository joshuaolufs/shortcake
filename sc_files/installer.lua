-- Delete any old versions
print("Removing old files, if they exist")
fs.delete("shortcake")
fs.delete("sc_files/config")
fs.delete("sc_files/t")

-- Get new files
print("Retrieving files from pastebin")
shell.run("pastebin", "get", "xerNNRAH", "shortcake") -- Download the interpreter
fs.makeDir("sc_files") -- Make a directory for the files
shell.run("pastebin", "get", "FFwyiJrH", "sc_files/t") -- Download the function library
shell.run("pastebin", "get", "DSreWan8", "sc_files/config") -- Download the config file