#!/usr/bin/bash 

printUsage(){
    echo "Usage: multigpg MODE ARCHIVE [FILE]
    MODE is one of the following:
    c
    create      : Creates a new GPG-encrypted archive named ARCHIVE. Please specify file name without extensions
    a
    add         : Adds FILE to ARCHIVE
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
        mode="create"
    elif [[ $1 = "add" || $1 = "a" ]]
    then
        mode="add"
    elif [[ $1 = "edit" || $1 = "e" ]]
    then
        mode="edit"
    elif [[ $1 = "password" || $1 = "pw" ]]
    then
        mode="password"
    elif [[ $1 = "writeback" || $1 = "wb" ]]
    then
        mode="writeback"
    elif [[ $1 = "discard" || $1 = "d" ]]
    then
        mode="discard"
    elif [[ $1 = "--help" ]]
    then
        mode="printUsage"
    else
        mode="printUsage"
    fi
    archive=$2
    decrypted_archive=$(basename $archive .gpg)
    working_dir=/tmp/multigpg/$archive
    file=$3
}

getPassword(){
    echo "Please enter the password:"
    #save password globally
    read -s password
}

confirmPassword(){
    echo "Please confirm your password:"
    read -s confirm_password
}

decrypt(){
    while [ -d $working_dir ]
    do
        working_dir=$working_dir\_other
    done
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
    #make variables globally available
    parseParameters "$@"
    if [[ $mode = "printUsage" ]]
    then 
        printUsage
    elif [[ $mode = "create" ]]
    then
        if [ -f $archive\.tar.gpg ]
        then
            echo "Archive already exists."
            exit 1
        fi
        getPassword
        #ask for password a second time to prevent typos
        confirmPassword
        if [[ "$password" = "$confirm_password" ]]
        then
            tar cT /dev/null -f $archive\.tar
            gpg --batch --passphrase $password --cipher-algo AES256 -c $archive\.tar
            rm $archive\.tar
        else
            echo "Passwords didn't match."
            exit 1
        fi
    elif [[ $mode = "add" ]]
    then
        getPassword
        decrypt
        tar -r $file -f $working_dir/$decrypted_archive
        writeback
        shred
    fi
fi
