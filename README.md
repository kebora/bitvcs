# bitvcs
`bitvcs` is a version control software that mirrors the functionality of `git`.

## Tests
First, verify that all tests can pass by running `flutter test`<br/>
If the test fails, the software might not have the writing permissions in the host OS.


## Documentation
Initialize a repository with the command: `dart run bitvcs init`, note the `.bitvcs` folder is created.<br/>
As a general overview, the file is moved across 3 key stages: `modified` stage while working on it, `staged` state when the desired changes have been appended, and `committed` stage for the whole feature.<br/>

Add any file from the working dir to `staged` state using command `dart run bitvcs add README.md`.<br/>
Commit the files using command `dart run bitvcs commit "any message"`<br/>
View the commit history using command `dart run bitvcs log`<br/>


