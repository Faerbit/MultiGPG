#!/usr/bin/bash

#Functional tests

firstLineUsage="Usage: multigpg MODE ARCHIVE [FILE]"
test_working_dir=/tmp/test_multigpg
cur_dir=$(pwd)

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

testClosedTempFileGetDeleted(){
    fail "Implement me!"
}

testPasswordGetsPreserved(){
    fail "Implement me!"
}

testChangePasswordModeChangesPassword(){
    fail "Implement me!"
}

testExistingArchiveGetsOpened(){
    fail "Implement me!"
}

testWriteBackModifiesArchive(){
    fail "Implement me!"
}

testDiscardDoesntModifyArchive(){
    fail "Implement me!"
}

testFileContentGetsPreserved(){
    fail "Implement me!"
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
    parseParameters writeback
    assertSame "$mode" "writeback"
    parseParameters wb
    assertSame "$mode" "writeback"
    parseParameters writeback archive
    assertSame "$mode" "writeback"
    assertSame "$archive" "archive"
    parseParameters wb archive
    assertSame "$mode" "writeback"
    assertSame "$archive" "archive"
}

testModeGetsChosenCorrectlyIfSpecified_discard(){
    parseParameters discard
    assertSame "$mode" "discard"
    parseParameters d
    assertSame "$mode" "discard"
    parseParameters discard archive
    assertSame "$mode" "discard"
    assertSame "$archive" "archive"
    parseParameters d archive
    assertSame "$mode" "discard"
    assertSame "$archive" "archive"
}

testWorkingDirIsChangedIfItAlreadyExists(){
    mkdir -p /tmp/multigpg/test_archive
    parseParameters add test_archive file
    assertNotSame "$working_dir" "/tmp/multigpg/test_archive"
    rmdir /tmp/multigpg/test_archive
    #ignore error message
    rmdir /tmp/multigpg 2> /dev/null
}

testDecrypt_correctPassword(){
    cd $test_working_dir
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
    #prevent weird error
    cd $cur_dir
}

testDecrypt_incorrectPassword(){
    cd $test_working_dir
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
    #prevent weird error
    cd $cur_dir
}

testWriteback(){
    cd $test_working_dir
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
    #prevent weird error
    cd $cur_dir
}

oneTimeSetUp(){
    source multigpg
}

setUp(){
    cd $cur_dir
    mkdir -p $test_working_dir
}

tearDown(){
    rm -rf $test_working_dir
}

#Run the tests/Load the test runner
source shunit2
