#!/usr/bin/bash

testPrintUsageIfNoOptionWasSpecified() {
    fail "Implement me!"
}

testOptionGetsChosenIfSpecified(){
    fail "Implement me!"
}

testCreateNewArchiveIfTheSpecifiedFileDoesntExist(){
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

testClosedArchiveGetsShredded(){
    fail "Implement me!"
}

testFileContentGetsPreserved(){
    fail "Implement me!"
}

testPasswordGetsPreserved(){
    fail "Implement me!"
}

testChangePasswordOptionChangesPassword(){
    fail "Implement me!"
}

oneTimeSetup(){
    source multigpg.sh
}

#Run the tests/Load the test runner
source shunit2
