import std/os
import std/strutils
import std/parseopt
import re


type
    CategoryPair* = object
        commit: string
        category: string
    Flags* = object
        startCommit: string
        endCommit: string
        verbose: bool


const helpText = """
Usage: nimclog [options]

Options:
  -h, --help               Show this help message
  -v, --verbose            Enable verbose output
  -s, --start=<revision>   Start git revision for the log range
  -e, --end=<revision>     End git revision for the log range

Examples:
  nimclog
  nimclog --start=<gitrevision> --end=<gitrevision>
  nimclog -s=<gitrevision> -e=<gitrevision>
"""

proc readParams():Flags =
    var flags = Flags(
        startCommit:"",
        endCommit:"",
        verbose: false
    )
    var resString = ""

    for param in commandLineParams():
        resString = resString & " " & param

    var parser = initOptParser(resString)

    while true:
        parser.next()
        case parser.kind
        of cmdEnd: break
        of cmdShortOption, cmdLongOption:
            case parser.key
            of "h","help":
                echo helpText
                quit(0)
            of "v","verbose":
                flags.verbose = true
            of "s","start":
                flags.startCommit = parser.val
            of "e","end":
                flags.endCommit = parser.val
            else: discard

        of cmdArgument: discard

    return flags

proc isValidRef(r: string): bool =
    return execShellCmd("git cat-file -e " & r) == 0

proc isAncestor(a, b: string): bool =
    return execShellCmd("git merge-base --is-ancestor " & a & " " & b) == 0

proc createInitialCommits*(flags: Flags) =
    when defined(posix):
        var startRef = flags.startCommit
        var endRef = flags.endCommit

        if startRef != "" and not isValidRef(startRef):
            echo("Warning: start ref '" & startRef & "' is not a valid repository ref, ignoring")
            startRef = ""

        if endRef != "" and not isValidRef(endRef):
            echo("Warning: end ref '" & endRef & "' is not a valid repository ref, ignoring")
            endRef = ""

        if startRef != "" and endRef != "":
            if not isAncestor(startRef, endRef):
                swap(startRef, endRef)
                if flags.verbose:
                    echo("Note: swapped start and end for correct ordering")

        var cmd = "git log"
        if startRef != "":
            cmd = cmd & " " & startRef
        if endRef != "":
            cmd = cmd & ".." & endRef
        cmd = cmd & " --pretty=oneline > commitlog.md"
        discard execShellCmd(cmd)


proc categorise*(commit: string): string =
    const categories = ["build","chore","ci","docs","feat","fix","perf","refactor","revert","style","test"]
    var selected: string;
    for i, cat in categories:
        if commit.startsWith(cat & ":"):
            selected = cat
            break;

    if selected == "":
        selected = "others"

    return selected


proc processInitialCommits*(): seq[CategoryPair] =
    var fileData = readFile("commitlog.md")
    # TODO:
    # manipulate log to categorise based on messages
    if(fileData.strip() == ""):
        echo("No commits found to process")
        quit(1)

    var eachCommit = fileData.split(Newlines)
    var categorized: seq[CategoryPair] = newSeq[CategoryPair](eachCommit.len);
    for commitLine in eachCommit:
        var dataSplit = commitLine.split(" ")
        var commitHash = dataSplit[0]
        var category = categorise(commitLine.replace(commitHash, "").strip())
        categorized.add(CategoryPair(
            commit: commitLine,
            category: category
        ))
    return categorized

proc printCategorized*(categorizedCommits: seq[CategoryPair]) =
    var commitStrings = ""

    for cPair in categorizedCommits:
        let templateStr = "{{" & cPair.category & "}}"
        if commitStrings.find(cPair.category.toUpper()) == -1:
            add(commitStrings, cPair.category.toUpper() & "\n----\n" &
                    templateStr & "\n\n");

        commitStrings = commitStrings
            .replace(templateStr & "\n", cPair.commit & "\n" & templateStr & "\n")

    commitStrings = commitStrings.replace(re"{{\w+}}", "")
    echo("\n" & commitStrings & "\n")

proc clean*() =
    removeFile("commitlog.md")

proc clog*() =
    when declared(commandLineParams):
        var flags = readParams()
        createInitialCommits(flags)
        var categorizedCommits = processInitialCommits();
        printCategorized(categorizedCommits)
        clean()
    else:
        echo "Failed to execute program..."
