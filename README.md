# Start-SVNPartialCommit
The module allows to split a bunch of changed files in your copy of SVN repository to several commits with defined max count of items in each. The total number of changed items splits into separate SVN changelists.

## Parameters

### -Repository
If the module starts in the SVN working folder, it is assumed that the current folder is exactly the copy of the target SVN repository for which you want to commit your changes. Otherwise, you should explicitly specify the path to the SVN repository.

### -SvnExe
Full path to the SVN client executable file. By default the module searches the executable in all paths included into your `'$env:PATH'` variable.

### -CommitMessage
Exactly what is written on the package. If your commit splits into a several commits, numbers from `'0'` will be added to the end of each message.

### -Count
Maximum count of changed items per single commit. If the parameter is not set or if the count of changed items is less or equal of number specified, all items will be committed by one transaction.

### -Encoding
The parameter specifies the encoding for reading the output of the `'svn status'` command. It suddenly becomes important if some of the paths in your repository contain characters of national alphabets (e.g. cyrillic). The default value is `'UTF8'`. And if you run `'svn status --xml'`, you can see that the `<XML declaration>` in output also points to UTF8 encoding. At least today, right now.

### -AutoAdd
If parameter **'AutoAdd'** is set, new unversioned items will be added under version control.

### -RemoveMissing
If parameter **'RemoveMissing'** is set, missing items (e.g. removed from your working folder with external command, not `'svn delete'`) will be **deleted** from version control!

### -SvnStatesValid
List of SVN states for changed items. The list loads from JSON file `'SVNStates.json'` in module's subfolder `'Data'`. Now contains `'deleted'`, `'added'`, `'modified'` and `'replaced'` states. You may override that.

### -SvnStatesInValid
List of SVN states for problem items. The list loads from JSON file `'SVNStates.json'` in module's subfolder `'Data'`. Now contains only `'missing'` state. You may override that.
