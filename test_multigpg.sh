#!/usr/bin/bash

#Functional tests

firstLineUsage="Usage: multigpg MODE ARCHIVE [OPTION]"

testPrintUsageIfNoParameterWasSpecified() {
    #check only for the first line of usage
    local output=$(./multigpg.sh | head -n 1)
    assertSame "$output" "$firstLineUsage"
}

testPrintUsageIfNoValidParametesWereSpecified() {
    #check only for the first line of usage
    local output=$(./multigpg.sh invalid | head -n 1)
    assertSame "$output" "$firstLineUsage"
}

testPrintUsageIfHelpWasSpecified() {
    #check only for the first line of usage
    local output=$(./multigpg.sh --help | head -n 1)
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

testModeGetsChosenIfSpecified(){
    local output=($(parseParameters create test))
    assertSame "${output[0]}" "create"
    assertSame "${output[1]}" "test"
    local output=($(parseParameters pw))
    assertSame "${output[0]}" "password"
    local output=($(parseParameters add test test2))
    assertSame "${output[0]}" "add"
    assertSame "${output[1]}" "test"
    assertSame "${output[2]}" "test2"
    local output=($(parseParameters e test2))
    assertSame "${output[0]}" "add"
    assertSame "${output[1]}" "test2"
}

testCreateNewArchiveIfTheSpecifiedFileDoesntExist(){
    fail "Implement me!"
}

testClosedArchiveGetsShredded(){
    fail "Implement me!"
}

testPasswordGetsPreserved(){
    fail "Implement me!"
}

testChangePasswordOptionChangesPassword(){
    fail "Implement me!"
}

oneTimeSetUp(){
    source multigpg.sh
}

#Run the tests/Load the test runner
source shunit2
