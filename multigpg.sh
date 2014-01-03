#!/usr/bin/bash 

printUsage(){
    echo "Usage: multigpg OPTION ARCHIVE [FILE]
        a
        add         : Adds FILE to the archive
        e
        edit        : Asks for the password, copies the contents of the archive to a /tmp folder and 
                      opens a custom shell for you to edit the contents
        pw
        password    : changes the password of the archive.

        The following commands are only available from the custom edit shell 
        and can be executed without calling multigpg first:

        wb
        writeback   : saves changes back to the archive and shreds the /tmp folder
        d
        discard     : discards changes and shreds the /tmp folder
        --help      : prints this help message."
}

printUsage
