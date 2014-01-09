#!/bin/bash

#Functional tests

firstLineUsage="Usage: multigpg MODE ARCHIVE [FILE]"
test_working_dir=/tmp/test_multigpg
current_directory=$(pwd)

testPrintUsageIfNoParameterWasSpecified() {
    #check only for the first line of usage
    local output=$(./multigpg | head -n 1)
    assertSame "$output" "$firstLineUsage"
}

testPrintUsageIfNoValidParametesWereSpecified() {
    #check only for the first line of usage
    local output=$(./multigpg invalid | head -n 1)
    assertSame "$output" "$firstLineUsage"
}

testPrintUsageIfHelpWasSpecified() {
    #check only for the first line of usage
    local output=$(./multigpg --help | head -n 1)
    assertSame "$output" "$firstLineUsage"
}

testAbortingIfArchiveDoesntExist(){
    touch testArchive.tar.gpg
    local output=$(parseParameters invalid notTestArchive.tar.gpg)
    assertSame "$output" "Archive doesn't exist. Aborting."
}

testCreateMode_samePassword(){
    local output=$(echo -e "secret\nsecret" | ./multigpg create test | paste -sd " ")
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg test.tar.gpg"
    assertSame "$output" "Please enter the password: Please confirm your password:" 
}

testCreateMode_differentPassword(){
    #simulate typo
    local output=$(echo -e "secret\nsercet" | ./multigpg create test | paste -sd " ")
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg"
    assertSame "$output" "Please enter the password: Please confirm your password: Passwords didn't match." 
}

testAddMode_NotDuplicate(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    local output=$(echo "secret" | ./multigpg add test.tar.gpg stuff)
    rm stuff
    gpg --batch --passphrase secret -o test.tar -d test.tar.gpg 2>/dev/null
    tar xf test.tar
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$hash_sum" "$test_hash_sum"
    assertSame "$output" "Please enter the password:"
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg stuff test.tar test.tar.gpg"
}

testAddMode_NotDuplicate_multipleFiles(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    echo "stuff" > otherstuff
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    echo "secret" | ./multigpg add test.tar.gpg otherstuff 2 > /dev/null
    rm stuff otherstuff
    gpg --batch --passphrase secret -o test.tar -d test.tar.gpg 2>/dev/null
    tar xf test.tar
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg otherstuff stuff test.tar test.tar.gpg"
}

testAddMode_Duplicate(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    #read
    local output=$(echo "secret" | ./multigpg add test.tar.gpg stuff| paste -sd " ")
    assertSame "$output" "Please enter the password: File already existed. Please use edit mode to update files."
}

testPasswordMode_samePassword(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local output=$(echo -e "secret\nothersecret\nothersecret" | ./multigpg password test.tar.gpg | paste -sd " ")
    gpg --batch --passphrase othersecret -o test.tar -d test.tar.gpg 2> /dev/null
    local ls_output1=$(ls | paste -sd " ")
    local ls_output2=$(ls /tmp | grep -e '^multigpg' | paste -sd " ")
    assertSame "$output" "Please enter the password: Please enter new password: Please confirm your password:"
    assertSame "$ls_output1" "multigpg test.tar test.tar.gpg"
    assertSame "$ls_output2" ""
}

testPasswordMode_differentPassword(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    #simulate typo
    local output=$(echo -e "secret\nothersecret\nothersercet" | ./multigpg password test.tar.gpg | paste -sd " ")
    local ls_output=$(ls /tmp | grep -e '^multigpg' | paste -sd " ")
    assertSame "$output" "Please enter the password: Please enter new password: Please confirm your password: Passwords didn't match."
    assertSame "$ls_output" ""
}

testExtractMode_FileExists(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    rm stuff
    local output=$(echo "secret" | ./multigpg extract test.tar.gpg stuff | paste -sd " ")
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$hash_sum" "$test_hash_sum"
    assertSame "$output" "Please enter the password:"
}

testExtractMode_FileDoesntExists(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local output=$(echo "secret" | ./multigpg extract test.tar.gpg nonexistent | paste -sd " ")
    assertSame "$output" "Please enter the password: File doesn't exist in this archive. Aborting."
}

testEditMode_ClosedTempFileGetDeleted(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local output=$(echo -e "secret\ndiscard" | ./multigpg edit test.tar.gpg | paste -sd " ")
    local ls_output=$(ls /tmp | grep -e '^multigpg' | paste -sd " ")
    assertSame "$ls_output" ""
    assertSame "$output" "Please enter the password: Please exit this shell with 'discard' or 'writeback'. Discarding changes."
}

testEditMode_ExistingArchiveGetsOpened(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    local output=$(echo -e "secret\nls\ndiscard" | ./multigpg edit test.tar.gpg | paste -sd " ")
    assertSame "$output" "Please enter the password: Please exit this shell with 'discard' or 'writeback'. stuff Discarding changes."
}

testEditMode_WriteBackModifiesArchive(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local hash_sum=$(sha512sum test.tar.gpg)
    local output=$(echo -e "secret\nwriteback" | ./multigpg edit test.tar.gpg | paste -sd " ")
    local test_hash_sum=$(sha512sum test.tar.gpg)
    #hash differ because of salted passwords
    assertNotSame "$hash_sum" "$test_hash_sum"
    assertSame "$output" "Please enter the password: Please exit this shell with 'discard' or 'writeback'. Writing changes back."
}

testEditMode_DiscardDoesntModifyArchive(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local hash_sum=$(sha512sum test.tar.gpg)
    local output=$(echo -e "secret\ndiscard" | ./multigpg edit test.tar.gpg | paste -sd " ")
    local test_hash_sum=$(sha512sum test.tar.gpg)
    assertSame "$hash_sum" "$test_hash_sum"
    assertSame "$output" "Please enter the password: Please exit this shell with 'discard' or 'writeback'. Discarding changes."
}

testEditMode_FileContentGetsPreserved(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    rm stuff
    echo -e "secret\ndiscard" | ./multigpg edit test.tar.gpg 2 > /dev/null
    echo -e "secret" | ./multigpg extract stuff 2 > /dev/null
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$hash_sum" "$test_hash_sum"
}

testEditMode_ExitDoesntExitShell(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local output=$(echo -e "secret\nexit\ndiscard" | ./multigpg edit test.tar.gpg 2 > /dev/null)
    assertSame "$output" "Please enter the password: Please exit this shell with 'discard' or 'writeback'. Please exit this shell with 'discard' or 'writeback'. Discarding changes."
}

#Unit tests

testModeGetsChosenCorrectlyIfSpecified_create(){
    parseParameters create testy
    assertSame "$mode" "create"
    assertSame "$archive" "testy"
    parseParameters c testy
    assertSame "$mode" "create"
    assertSame "$archive" "testy"
}

testModeGetsChosenCorrectlyIfSpecified_add(){
    touch testy
    parseParameters add testy test2
    assertSame "$mode" "add"
    assertSame "$archive" "testy"
    assertSame "$file" "test2"
    parseParameters a testy test2
    assertSame "$mode" "add"
    assertSame "$archive" "testy"
    assertSame "$file" "test2"
}

testModeGetsChosenCorrectlyIfSpecified_edit(){
    touch test2
    parseParameters edit test2
    assertSame "$mode" "edit"
    assertSame "$archive" "test2"
    parseParameters e test2
    assertSame "$mode" "edit"
    assertSame "$archive" "test2"
}


testModeGetsChosenCorrectlyIfSpecified_password(){
    parseParameters password
    assertSame "$mode" "password"
    parseParameters pw
    assertSame "$mode" "password"
}

testModeGetsChosenCorrectlyIfSpecified_writeback(){
    touch archiveee
    parseParameters writeback
    assertSame "$mode" "writeback"
    parseParameters wb
    assertSame "$mode" "writeback"
    parseParameters writeback archiveee
    assertSame "$mode" "writeback"
    assertSame "$archive" "archiveee"
    parseParameters wb archiveee
    assertSame "$mode" "writeback"
    assertSame "$archive" "archiveee"
}

testModeGetsChosenCorrectlyIfSpecified_discard(){
    touch archiveee
    parseParameters discard
    assertSame "$mode" "discard"
    parseParameters d
    assertSame "$mode" "discard"
    parseParameters discard archiveee
    assertSame "$mode" "discard"
    assertSame "$archive" "archiveee"
    parseParameters d archiveee
    assertSame "$mode" "discard"
    assertSame "$archive" "archiveee"
}

testModeGetsChosenCorrectlyIfSpecified_extract(){
    touch archiveee
    parseParameters extract archiveee stuff
    assertSame "$mode" "extract"
    assertSame "$archive" "archiveee"
    assertSame "$file" "stuff"
    parseParameters ex archiveee stuff
    assertSame "$mode" "extract"
    assertSame "$archive" "archiveee"
    assertSame "$file" "stuff"
}

testWorkingDirIsChangedIfItAlreadyExists(){
    touch test_archive
    mkdir -p /tmp/multigpg/test_archive
    parseParameters add test_archive file
    assertNotSame "$working_dir" "/tmp/multigpg/test_archive"
    rmdir /tmp/multigpg/test_archive
    #ignore error message
    rmdir /tmp/multigpg 2> /dev/null
}
testDecrypt_correctPassword(){
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    gpg --batch --passphrase secret --cipher-algo AES256 -c stuff
    #to set global variables
    parseParameters invalid stuff.gpg
    password="secret"
    decrypt
    cd $working_dir
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$test_hash_sum" "$hash_sum"
    #cleanup 
    rm -rf ../stuff.gpg
}

testDecrypt_incorrectPassword(){
    echo "stuff" > stuff
    gpg --batch --passphrase secret --cipher-algo AES256 -c stuff
    #to set global variables
    parseParameters invalid stuff.gpg
    password="anothersecret"
    local output=$(decrypt)
    assertSame "$output" "Your password didn't work or something else went wrong."
    #cleanup
    cd $working_dir
    rm -rf ../stuff.gpg
}

testWriteback_modifiesArchive(){
    echo "stuff" > stuff
    gpg --batch --passphrase secret --cipher-algo AES256 -c stuff
    local hash_sum=$(sha512sum stuff.gpg)
    #to set global variables
    parseParameters invalid stuff.gpg
    password="secret"
    decrypt
    writeback
    local test_hash_sum=$(sha512sum stuff.gpg)
    #gpg archive differs because of salted passphrase
    assertNotSame "$test_hash_sum" "$hash_sum"
    #cleanup 
    cd $working_dir
    rm -rf ../stuff.gpg
}

testWriteback_preservesPassword(){
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    gpg --batch --passphrase secret --cipher-algo AES256 -c stuff
    #to set global variables
    parseParameters invalid stuff.gpg
    password="secret"
    decrypt
    writeback
    rm stuff
    gpg --batch --passphrase secret -o stuff -d stuff.gpg 2> /dev/null
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$hash_sum" "$test_hash_sum"
    #cleanup 
    cd $working_dir
    rm -rf ../stuff.gpg
}

testShred_onlyFiles(){
    #set working dir for shred
    working_dir=$test_working_dir/shred_test
    mkdir $test_working_dir/shred_test
    cd $test_working_dir/shred_test
    echo "stuff" > stuff
    echo "otherstuff" > otherstuff
    echo "foo" > foo
    echo "bar" > bar
    shred
    local ls_output=$(ls)
    assertSame "$ls_output" ""
}

testShred_withFolders(){
    #set working dir for shred
    working_dir=$test_working_dir/shred_test
    mkdir $test_working_dir/shred_test
    cd $test_working_dir/shred_test
    echo "stuff" > stuff
    mkdir otherstuff
    echo "otherstuff" > ./otherstuff/otherstuff
    echo "foo" > foo
    mkdir bar
    echo "bar" > ./bar/bar
    shred
    local ls_output=$(ls)
    assertSame "$ls_output" ""
}

testUntar(){
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    tar c stuff -f archive.tar
    #set global variables
    working_dir=$test_working_dir
    decrypted_archive=archive.tar
    untar
    cd archive
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$test_hash_sum" "$hash_sum"
}

testPack_Tar(){
    mkdir archive
    echo "stuff" > archive/stuff
    local hash_sum=$(sha512sum archive/stuff)
    #set global variables
    working_dir=$test_working_dir
    decrypted_archive=archive.tar
    pack_tar
    rm -rf archive 
    untar
    local ls_output=$(ls archive)
    local test_hash_sum=$(sha512sum archive/stuff)
    assertSame "$ls_output" "stuff"
    assertSame "$test_hash_sum" "$hash_sum"
}

oneTimeSetUp(){
    source multigpg
    #alias to simulate the script as installed in the path
    alias multigpg='./multigpg'
    # delete any leftovers
    rm -rf /tmp/multigpg
}

oneTimeTearDown(){
# delete any leftovers
    rm -rf /tmp/multigpg
    unalias multigpg
}

setUp(){
    mkdir -p $test_working_dir
    cp $current_directory/multigpg $test_working_dir/multigpg
    cd $test_working_dir
    
}

tearDown(){
    rm -rf $test_working_dir
    #prevent weird error from shunit2
    cd /tmp
}

#Run the tests/Load the test runner
source shunit2
