#!/usr/bin/bash

#Functional tests

firstLineUsage="Usage: multigpg MODE ARCHIVE [FILE]"

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
    rmdir /tmp/multigpg
}

testClosedTempFileGetDeleted(){
    fail "Implement me!"
}

testPasswordGetsPreserved(){
    fail "Implement me!"
}

testChangePasswordOptionChangesPassword(){
    fail "Implement me!"
}

oneTimeSetUp(){
    source multigpg
}

#Run the tests/Load the test runner
source shunit2
