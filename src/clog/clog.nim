import std/os
import std/strutils
import re


type
    CategoryPair* = object
        commit: string
        category: string


proc createInitialCommits*() =
    when defined(posix):
        # TODO:
        # handle params where you get the start and end commit
        discard execShellCmd("git log --pretty=oneline > commitlog.md")


proc categorise*(commit: string): string =
    const categories = ["ci", "feat", "fix", "others"]
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
    createInitialCommits()
    var categorizedCommits = processInitialCommits();
    printCategorized(categorizedCommits)
    clean()





