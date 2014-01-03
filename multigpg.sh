#!/usr/bin/bash 

printUsage(){
    echo "Usage: multigpg MODE ARCHIVE [OPTION]
    MODE is one of the following:
    c
    create      : Creates a new GPG-encrypted archive named ARCHIVE. Please specify file name without extensions
    a
    add         : Adds OPTION to ARCHIVE
    e
    edit        : Copies the contents of the archive to a /tmp folder and 
                  opens a custom shell for you to edit the contents
    pw
    password    : Changes the password of ARCHIVE

    The following commands are only available from the custom edit shell 
    and can be executed without calling multigpg first:
    wb
    writeback   : saves changes back to the archive and shreds the /tmp folder
    d
    discard     : discards changes and shreds the /tmp folder
    --help      : prints this help message."
}

parseParameters(){
    if [[ $1 = "create" || $1 = "c" ]]
    then
        echo "create $2"
    elif [[ $1 = "add" || $1 = "a" ]]
    then
        echo "add $2 $3"
    elif [[ $1 = "edit" || $1 = "e" ]]
    then
        echo "edit $2"
    elif [[ $1 = "password" || $1 = "pw" ]]
    then
        echo "password $2"
    elif [[ $1 = "writeback" || $1 = "wb" ]]
    then
        echo "writeback"
    elif [[ $1 = "discard" || $1 = "d" ]]
    then
        echo "discard"
    elif [[ $1 = "--help" ]]
    then
        echo "printUsage"
    else
        echo "printUsage"
    fi
}

#only start execution if script is executed directly
if [[ $(basename $0) = "multigpg.sh" ]]
then
    parameters=($(parseParameters "$@"))
    if [[ ${parameters[0]} = "printUsage" ]]
    then 
        printUsage
    fi
fi
