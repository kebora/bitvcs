# bitvcs
`bitvcs` is a version control software that mirrors the functionality of `git`.

## Tests
First, verify that all tests can pass by running `flutter test`<br/>
If the test fails, the software might not have the writing permissions in the host OS.


## Documentation
As a general overview, the file is moved across 3 key stages: `modified` stage while working on it, `staged` state when the desired changes have been added, and `committed` stage for the whole feature.<br/>

View all the available commands using `dart run bitvcs help`<br/>
Initialize a repository with the command: `dart run bitvcs init`, note the `.bitvcs` folder is created.<br/>
Add any file from the working dir to `staged` state using command `dart run bitvcs add "fileName"`<br/>
Commit the files using command `dart run bitvcs commit "any message"`<br/>
View the commit history using command `dart run bitvcs log`<br/>
Create a new branch using command `dart run bitvcs branch "branchName"`<br/>
Clone the Repository using command `dart run bitvcs clone "destinationPath"`<br/>
Merge Repositories using command `dart run bitvcs merge "sourceBranch"`
The targetBranch is set to `main`.