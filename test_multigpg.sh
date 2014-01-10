#!/bin/bash

test_working_dir=/tmp/test_multigpg
current_directory=$(pwd)

#Functional tests

testPrintUsageIfNoParameterWasSpecified() {
    local output=$(./multigpg | sed 's/ //g')
    local cleansed_usage=$(echo "$string_usage" | paste -sd " " | sed 's/ //g')
    assertSame "$output" "$cleansed_usage"
}

testPrintUsageIfNoValidParametesWereSpecified() {
    local output=$(./multigpg invalid | sed 's/ //g')
    local cleansed_usage=$(echo "$string_usage" | paste -sd " " | sed 's/ //g')
    assertSame "$output" "$cleansed_usage"
}

testPrintUsageIfHelpWasSpecified() {
    local output=$(./multigpg --help| sed 's/ //g')
    local cleansed_usage=$(echo "$string_usage" | paste -sd " " | sed 's/ //g')
    assertSame "$output" "$cleansed_usage"
}

testAbortingIfArchiveDoesntExist(){
    touch testArchive.tar.gpg
    local output=$(parseParameters invalid notTestArchive.tar.gpg)
    assertSame "$output" "$string_archive_missing"
}

testCreateMode_samePassword(){
    local output=$(echo -e "secret\nsecret" | ./multigpg create test | paste -sd " ")
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg test.tar.gpg"
    assertSame "$output" "$string_enter_password $string_confirm_password"
}

testCreateMode_differentPassword(){
    #simulate typo
    local output=$(echo -e "secret\nsercet" | ./multigpg create test | paste -sd " ")
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg"
    assertSame "$output" "$string_enter_password $string_confirm_password $string_wrong_password_typo" 
}

testListMode_oneFile(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    local output=$(echo "secret" | ./multigpg list test.tar.gpg | paste -sd " ")
    assertSame "$output" "$string_enter_password stuff"
}

testListMode_multipleFiles(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    mkdir some_dir
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    echo "secret" | ./multigpg add test.tar.gpg some_dir 2 > /dev/null
    local output=$(echo "secret" | ./multigpg list test.tar.gpg | paste -sd " ")
    assertSame "$output" "$string_enter_password some_dir stuff"
}

testAddMode_NotDuplicate(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    local output=$(echo "secret" | ./multigpg add test.tar.gpg stuff)
    gpg --batch --passphrase secret -o test.tar -d test.tar.gpg 2>/dev/null
    tar xf test.tar
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$hash_sum" "$test_hash_sum"
    assertSame "$output" "$string_enter_password"
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg stuff test.tar test.tar.gpg"
}


testAddMode_NotDuplicate_directory(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    mkdir test_dir
    echo "stuff" > test_dir/stuff
    local output=$(echo "secret" | ./multigpg add test.tar.gpg test_dir)
    gpg --batch --passphrase secret -o test.tar -d test.tar.gpg 2>/dev/null
    tar xf test.tar
    local ls_output=$(ls test_dir)
    assertSame "$output" "$string_enter_password"
    assertSame "$ls_output" "stuff"
}

testAddMode_ShredsFile(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    local output=$(echo "secret" | ./multigpg add test.tar.gpg stuff)
    local ls_output=$(ls | paste -sd " ")
    assertSame "$output" "$string_enter_password"
    assertSame "$ls_output" "multigpg test.tar.gpg"
}

testAddMode_ShredsDirectory(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    mkdir stuff
    local output=$(echo "secret" | ./multigpg add test.tar.gpg stuff)
    local ls_output=$(ls | paste -sd " ")
    assertSame "$output" "$string_enter_password"
    assertSame "$ls_output" "multigpg test.tar.gpg"
}

testAddMode_NotDuplicate_multipleFiles(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    echo "stuff" > otherstuff
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    echo "secret" | ./multigpg add test.tar.gpg otherstuff 2 > /dev/null
    gpg --batch --passphrase secret -o test.tar -d test.tar.gpg 2>/dev/null
    tar xf test.tar
    local ls_output=$(ls | paste -sd " ")
    assertSame "$ls_output" "multigpg otherstuff stuff test.tar test.tar.gpg"
}

testAddMode_Duplicate_replace(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    local output=$(echo -e "secret\ny" | ./multigpg add test.tar.gpg stuff| paste -sd " ")
    assertSame "$output" "$string_enter_password $string_replace_file"
}

testAddMode_Duplicate_directory_replace(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    mkdir test_dir
    echo "stuff" > test_dir/stuff
    echo "secret" | ./multigpg add test.tar.gpg test_dir 2 > /dev/null
    local output=$(echo -e "secret\ny" | ./multigpg add test.tar.gpg test_dir | paste -sd " ")
    assertSame "$output" "$string_enter_password $string_replace_file"
}

testAddMode_Duplicate_dontReplace(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    local output=$(echo -e "secret\nn" | ./multigpg add test.tar.gpg stuff| paste -sd " ")
    gpg --batch --passphrase secret -o test.tar -d test.tar.gpg 2>/dev/null
    tar xf test.tar
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$output" "$string_enter_password $string_replace_file"
    assertSame "$hash_sum" "$test_hash_sum"
}

testPasswordMode_samePassword(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local output=$(echo -e "secret\nothersecret\nothersecret" | ./multigpg password test.tar.gpg | paste -sd " ")
    gpg --batch --passphrase othersecret -o test.tar -d test.tar.gpg 2> /dev/null
    local ls_output1=$(ls | paste -sd " ")
    local ls_output2=$(ls /tmp | grep -e '^multigpg' | paste -sd " ")
    assertSame "$output" "$string_enter_password $string_new_password $string_confirm_password"
    assertSame "$ls_output1" "multigpg test.tar test.tar.gpg"
    assertSame "$ls_output2" ""
}

testPasswordMode_differentPassword(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    #simulate typo
    local output=$(echo -e "secret\nothersecret\nothersercet" | ./multigpg password test.tar.gpg | paste -sd " ")
    local ls_output=$(ls /tmp | grep -e '^multigpg' | paste -sd " ")
    assertSame "$output" "$string_enter_password $string_new_password $string_confirm_password $string_wrong_password_typo"
    assertSame "$ls_output" ""
}

testExtractMode_FileExists(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    echo "stuff" > stuff
    local hash_sum=$(sha512sum stuff)
    echo "secret" | ./multigpg add test.tar.gpg stuff 2 > /dev/null
    local output=$(echo "secret" | ./multigpg extract test.tar.gpg stuff | paste -sd " ")
    local test_hash_sum=$(sha512sum stuff)
    assertSame "$hash_sum" "$test_hash_sum"
    assertSame "$output" "$string_enter_password"
}

testExtractMode_FileExists_directory(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    mkdir some_dir
    echo "stuff" > some_dir/stuff
    echo "secret" | ./multigpg add test.tar.gpg some_dir 2 > /dev/null
    local output=$(echo "secret" | ./multigpg extract test.tar.gpg some_dir | paste -sd " ")
    local ls_output=$(ls some_dir)
    assertSame "$output" "$string_enter_password"
    assertSame "$ls_output" "stuff"
}

testExtractMode_FileDoesntExists(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    local output=$(echo "secret" | ./multigpg extract test.tar.gpg nonexistent | paste -sd " ")
    assertSame "$output" "$string_enter_password $string_file_missing"
}

testExtractMode_all(){
    echo -e "secret\nsecret" | ./multigpg create test 2 > /dev/null
    mkdir some_dir
    echo "stuff" > some_dir/stuff
    echo "otherstuff" > otherstuff
    echo "secret" | ./multigpg add test.tar.gpg some_dir 2 > /dev/null
    echo "secret" | ./multigpg add test.tar.gpg otherstuff 2 > /dev/null
    local output=$(echo "secret" | ./multigpg extract test.tar.gpg all | paste -sd " ")
    local ls_output1=$(ls | paste -sd " ")
    local ls_output2=$(ls some_dir)
    assertSame "$output" "$string_enter_password"
    assertSame "$ls_output1" "multigpg otherstuff some_dir test.tar.gpg"
    assertSame "$ls_output2" "stuff"
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

testModeGetsChosenCorrectlyIfSpecified_password(){
    parseParameters password
    assertSame "$mode" "password"
    parseParameters pw
    assertSame "$mode" "password"
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

testModeGetsChosenCorrectlyIfSpecified_list(){
    touch test_archive
    parseParameters list test_archive 
    assertSame "$mode" "list"
    assertSame "$archive" "test_archive"
    parseParameters ls test_archive 
    assertSame "$mode" "list"
    assertSame "$archive" "test_archive"
}

testModeGetsChosenCorrectlyIfSpecified_delete(){
    touch test_archive
    parseParameters delete test_archive garbage
    assertSame "$mode" "delete"
    assertSame "$archive" "test_archive"
    assertSame "$file" "garbage"
    parseParameters d test_archive garbage
    assertSame "$mode" "delete"
    assertSame "$archive" "test_archive"
    assertSame "$file" "garbage"
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
    assertSame "$output" "$string_wrong_password"
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
    shred_tmp
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
    shred_tmp
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
    #populate strings globally
    populateStrings
    # delete any leftovers
    rm -rf /tmp/multigpg
}

oneTimeTearDown(){
# delete any leftovers
    rm -rf /tmp/multigpg
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
