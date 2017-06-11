-- Delete any old versions
shell.run("delete", "shortcake")
shell.run("delete", "sc_files")

-- Get new files
shell.run("pastebin", "get", "xerNNRAH", "shortcake") -- Download the interpreter
shell.run("mkdir", "sc_files") -- Make a directory for the files
shell.run("cd", "sc_files") -- Navigate to the shortcake directory
shell.run("pastebin", "get", "FFwyiJrH", "t") -- Download the function library
shell.run("pastebin", "get", "DSreWan8", "config") -- Download the config file
shell.run("cd", "..") -- Navigate back to the starting directory