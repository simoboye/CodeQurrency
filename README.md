# CodeQurrency
Research project as part of our studies in computer science at the IT University of Copenhagen.

## Create a database

codeql database create <path-to-create> --language=java --source-root <path-to-java-repo-with-gradle>

I had some issues when the path contains Ø.

An example for me is:

..\..\..\..\..\..\codeql\codeql database create ../../../../../../week1-database --language=java --source-root .\PCPP2022-Public-TeamDP\week01\code-exercises\week01exercises\ --overwrite

## Create generate markdown file from .qhelp

codeql generate query-help .\queries\immutable-fields.qhelp --format markdown --output .\queries\immutable-fields.md
