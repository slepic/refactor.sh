# refactor.sh
Unix Shell Tool for Bulk File Modification

This tool provides an interface to modify many files at once, maintaining overview of the modifications and ways to make manual corrections before the changes get accepted, as well as ways to restore original state if something goes wrong.

Usage:
	1) refactor.sh -h
	2) refactor.sh -p PATTERN [-r REPLACEMENT] [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]
	3) refactor.sh -P PATTERN [-R REPLACEMENT] [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]
	4) refactor.sh -l [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]
	5) refactor.sh -d [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]
	6) refactor.sh -a|-A [-b [-S SUFFIX]] [-e EDITOR] [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]
	7) refactor.sh -c|-C [-s SUFFIX] [-f FILENAME] [-w DIRECTORY]
	8) refactor.sh -t|-T [-S SUFFIX] [-f FILENAME] [-w DIRECTORY]
	9) refactor.sh -u [-S SUFFIX] [-f FILENAME] [-w DIRECTORY]

Use case description:
	1) Print help
	2) Replace simple pattern
	3) Replace regex pattern
	4) List changed files
	5) Diff current changes to original
	6) Accept changes
	7) Cleanup changes
	8) Remove backup files
	9) Undo accepted changes

	Note: Most of the cases (except -h) can be combined together to execute in one go.

Operations order:
	1. Undo modified original files (-u)
	2. Remove backups of original files (-t|-T)
	3. Do replacements (-p|-P)
	4. List changes (-l)
	5. Diff changes (-d)
	6. Backup original files (-b)
	7. Accept changes (-a|-A)
	8. Cleanup modifications (-c|-C)

Options:
	-a, --accept             Accept changes.
	-A, --force-accept       Accept changes without prompt (implies -a; accept with yes-to-all prompts)
	-b, --backup             Backup files upon accept (combine with -a or -A; implies -a) 
	-c, --cleanup            Remove working files. You will be asked to confirm each file deletion.
	-C, --force-cleanup      Remove working files without prompt (implies -c)
	-d, --diff               Show diff
	-e, --editor             Set editor to use for edit before accept (combine with -a, useless with -A). Defaults to "vim -p"
	-f, --filename           Filename pattern, apply operations on files matching this pattern only. Defaults to "*"
	-h, --help               Print this help
	-l, --list               List modified files
	-p, --pattern            Pattern to search for
	-P, --regex-pattern      Regular expression pattern to search for
	-r, --replacement        Replace pattern with replacement string
	-R, --regex-replacement  Replace pattern with replacement string
	-s, --suffix             Suffix for working files. Defaults to "refactored".
	-S, --backup-suffix      Suffix for backup files. Defaults to "refactored.backup".
	-t, --tidy               Remove backup files. You will be asked to confirm each file deletion.
	-T, --force-tidy         Remove backup files without prompt (implies -t)
	-u, --undo               Undo accepted changes (a backup must be created using -b and not removed using -t or -T for this to work)
	-w, --working-directory  Working directory to look files under. Defaults to $PWD

	Note: Long options dont work yet.
