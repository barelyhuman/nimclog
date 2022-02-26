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


proc readParams():Flags = 
    var flags = Flags(
        startCommit:"",
        endCommit:""    
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
            if parser.val == "":
                echo "hello"
            else:
                case parser.key
                of "s","start":
                    flags.startCommit = parser.val
                of "e","end":
                    flags.endCommit = parser.val    
                
        of cmdArgument:
            echo "Argument: ", parser.key
    
    return flags

proc createInitialCommits*(flags:Flags) =
    when defined(posix):
        var cmd = "git log"
        if flags.startCommit != "":
            cmd = cmd & " " & flags.startCommit
        if flags.endCommit != "":
            cmd = cmd & " " & flags.endCommit
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