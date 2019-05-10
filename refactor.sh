#!/bin/bash

script=$0
scriptName=$(basename "$script")
exitCode=0
defaultEditor="vim -p"
defaultFilename="*"
defaultDirectory="$PWD"
defaultSuffix="refactored"
defaultBackupSuffix="refactored.backup"



function print_help {
	echo "$scriptName: Refactoring utility";
	echo "This tool provides an interface to modify many files at once, maintaining overview of the modifications and ways to make manual corrections before the changes get accepted, as well as ways to restore original state if something goes wrong.";

	echo ""
	echo "Usage:";
	printf "\t1) $scriptName -h\n";
	printf "\t2) $scriptName -p PATTERN [-r REPLACEMENT] [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";
	printf "\t3) $scriptName -P PATTERN [-R REPLACEMENT] [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";
	printf "\t4) $scriptName -l [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";
	printf "\t5) $scriptName -d [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";
	printf "\t6) $scriptName -a|-A [-b [-S SUFFIX]] [-e EDITOR] [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";
	printf "\t7) $scriptName -c|-C [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";
	printf "\t8) $scriptName -t|-T [-S SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";
	printf "\t9) $scriptName -u [-S SUFFIX] [-f FILENAME] [-w DIRECTORY]\n";

	echo ""
	echo "Use case description:"
	printf "\t1) Print help\n";
	printf "\t2) Replace simple pattern\n"
	printf "\t3) Replace regex pattern\n"
	printf "\t4) List changed files\n"
	printf "\t5) Diff current changes to original\n"
	printf "\t6) Accept changes\n"
	printf "\t7) Cleanup changes\n"
	printf "\t8) Remove backup files\n"
	printf "\t9) Undo accepted changes\n"
	printf "\n\tNote: Most of the cases (except -h) can be combined together to execute in one go.\n"

	echo ""
	echo "Operations order:"
	printf "\t1. Undo modified original files (-u)\n"
	printf "\t2. Remove backups of original files (-t|-T)\n"
	printf "\t3. Do replacements (-p|-P)\n"
	printf "\t4. List changes (-l)\n"
	printf "\t5. Diff changes (-d)\n"
	printf "\t6. Backup original files (-b)\n"
	printf "\t7. Accept changes (-a|-A)\n"
	printf "\t8. Cleanup modifications (-c|-C)\n"

	echo ""
	echo "Options:";
	printf "\t-a, --accept             Accept changes.\n";
	printf "\t-A, --force-accept       Accept changes without prompt (implies -a; accept with yes-to-all prompts)\n";
	printf "\t-b, --backup             Backup files upon accept (combine with -a or -A; implies -a) \n";
	printf "\t-c, --cleanup            Remove working files. You will be asked to confirm each file deletion.\n";
	printf "\t-C, --force-cleanup      Remove working files without prompt (implies -c)\n";
	printf "\t-d, --diff               Show diff\n";
	printf "\t-e, --editor             Set editor to use for edit before accept (combine with -a, useless with -A). Defaults to \"$defaultEditor\"\n";
	printf "\t-f, --filename           Filename pattern, apply operations on files matching this pattern only. Defaults to \"$defaultFilename\"\n";
	printf "\t-h, --help               Print this help\n";
	printf "\t-l, --list               List modified files\n";
	printf "\t-p, --pattern            Pattern to search for\n";
	printf "\t-P, --regex-pattern      Regular expression pattern to search for\n";
	printf "\t-r, --replacement        Replace pattern with replacement string\n";
	printf "\t-R, --regex-replacement  Replace pattern with replacement string\n";
	printf "\t-s, --suffix             Suffix for working files. Defaults to \"$defaultSuffix\".\n";
	printf "\t-S, --backup-suffix      Suffix for backup files. Defaults to \"$defaultBackupSuffix\".\n";
	printf "\t-t, --tidy               Remove backup files. You will be asked to confirm each file deletion.\n";
	printf "\t-T, --force-tidy         Remove backup files without prompt (implies -t)\n";
	printf "\t-u, --undo               Undo accepted changes (a backup must be created using -b and not removed using -t or -T for this to work)\n";
	printf "\t-w, --working-directory  Working directory to look files under. Defaults to \$PWD\n";
	printf "\n\tNote: Long options dont work yet.\n";
}


function error_occured {
	echo "$1" >&2
	exit 1
}

#default setting
doAccept=0
forceAccept=0
doBackup=0
doCleanup=0
forceCleanup=0
doDiff=0
editor="$defaultEditor"
filename="$defaultFilename"
doHelp=0
doList=0
pattern=""
regexPattern=""
replacement=""
regexReplacement=""
suffix="$defaultSuffix"
backupSuffix="$defaultBackupSuffix"
doReplace=0
doTidy=0
forceTidy=0
doUndo=0
directory="$defaultDirectory"

function parse_arguments {
	while getopts "aAbcCdhltTue:f:p:P:r:R:s:S:w:" opt; do
		case "$opt" in
		a) doAccept=1;;
		A) doAccept=1;forceAccept=1;;
		b) doBackup=1;doAccept=1;;
		c) doCleanup=1;;
		C) doCleanup=1;forceCleanup=1;;
		d) doDiff=1;;
		e) editor="$OPTARG";;
		f) filename="$OPTARG";;
		h) doHelp=1;;
		l) doList=1;;
		p) pattern="$OPTARG";doReplace=1;;
		P) regexPattern="$OPTARG";doReplace=1;;
		r) replacement="$OPTARG";;
		R) regexReplacement="$OPTARG";;
		s) suffix="$OPTARG";;
		S) backupSuffix="$OPTARG";;
		t) doTidy=1;;
		T) doTidy=1;forceTidy=1;;
		u) doUndo=1;;
		w) directory="$OPTARG";;
		\?) exit 1;;
		esac
	done
}

parse_arguments "$@"
directory="$(readlink -f "$directory")"

function check_setting {
	#working directory
	test ! -e "$directory" && error_occured "Working directory '$directory' does not exist."
	test ! -d "$directory" && error_occured "'$directory' is not a directory."
	test ! -r "$directory" && error_occured "No read permission on working directory."
	test ! -w "$directory" && error_occured "No write permission on working directory."
	test ! -x "$directory" && error_occured "No execute permission on working directory."

	#accept
	test $forceAccept -eq 1 && test "$editor" != "$defaultEditor" && error_occured "Combination of options -A and -e makes no sense." 


	#suffix
	test "$suffix" != "$defaultSuffix" && \
		test $doReplace -ne 1 && \
		test $doDiff -ne 1 && \
		test $doAccept -ne 1 && \
		test $doCleanup -ne 1 && \
		error_occured "Option -s must be combined with -p, -P, -d, -a, -A, -c or -C"

	test "$backupSuffix" != "$defaultBackupSuffix" && \
		test $doBackup -ne 1 && \
		test $doTidy -ne 1 && \
		error_occured "Option -S must be combined with -b, -t or -T"

	#TODO
	#test help is alone
	#test at least one operation selected
}

check_setting

test $doHelp -eq 1 && print_help && exit 0

function main_loop {

find "$directory" -type f -name "$filename" |while read line
do
	originalFile=`echo "$line"|sed s/\.$suffix$//|sed s/\.$backupSuffix$//`
	test "$line" != "$originalFile" && continue
	refactoredFile=$originalFile.$suffix
	backupFile=$originalFile.$backupSuffix

	test $doUndo -eq 1 && undo_changes
	test $doTidy -eq 1 && remove_backup
	test $doReplace -eq 1 && make_replacements
	test $doList -eq 1 && list_changes
	test $doDiff -eq 1 && diff_changes
	test $doBackup -eq 1 && make_backup
	test $doAccept -eq 1 && accept_changes
	test $doCleanup -eq 1 && cleanup_changes

done
}

function undo_changes {
	test -f "$backupFile" && cp "$backupFile" "$originalFile" && echo "UNDO: $originalFile"
}

function remove_backup {
	test -f "$backupFile" && rm "$backupFile" && echo "BACKUP: $originalFile"
}

function make_replacements {
	#TODO rather provide while s///g from program arguments to be more generic
	sed "s/${pattern}/${replacement}/g" "$originalFile" > "$refactoredFile"
	test -z "$(diff_changes)" && cleanup_changes > /dev/null || echo "REPLACE: $originalFile"
}

function list_changes {
	test -f "$refactoredFile" && echo "$originalFile"
}

function diff_changes {
	test -f "$refactoredFile" && diff -up "$originalFile" "$refactoredFile"
}

function make_backup {
	cp "$originalFile" "$backupFile" && echo "BACKUP CREATED: $originalFile"
}

function accept_changes {
	test -f "$refactoredFile" && cp "$refactoredFile" "$originalFile" && echo "ACCEPTED: $originalFile"
}

function cleanup_changes {
	test -f "$refactoredFile" && rm "$refactoredFile" && echo "CLEANED: $originalFile"
}

main_loop

exit $exitCode
