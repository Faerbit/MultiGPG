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

getPassword(){
    echo "Please input the password:"
    #save password globally
    read -s password
}

decrypt(){
    mkdir -p $working_dir
    gpg --batch --passphrase $password -o "$working_dir/$decrypted_archive" -d $archive
}

writeback(){
    gpg --batch --yes --passphrase $password --cipher-algo AES256 -o $archive -c "$working_dir/$decrypted_archive" 
}

shred(){
    #recursively shred all files
    find $working_dir -type f -execdir shred -un 1 '{}' \;
    rmdir $working_dir
    rmdir /tmp/multigpg 2> /dev/null
}

#only start execution if script is executed directly
if [[ $(basename $0) = "multigpg.sh" ]]
then
    parameters=($(parseParameters "$@"))
    if [[ ${parameters[0]} = "printUsage" ]]
    then 
        printUsage
    elif [[ ${parameters[0]} = "create" ]]
    then
        archive=${parameters[1]}
        getPassword
        tar cT /dev/null -f $archive\.tar
        gpg --batch --passphrase $password --cipher-algo AES256 -c $archive\.tar
        rm $archive\.tar
    elif [[ ${parameters[0]} = "add" ]]
    then
        archive=${parameters[1]}
        decrypted_archive=$(basename $archive .gpg)
        file=${parameters[2]}
        working_dir=/tmp/multigpg/$archive
        getPassword
        decrypt
        tar -r $file -f $working_dir/$decrypted_archive
        writeback
        shred
    fi
fi
