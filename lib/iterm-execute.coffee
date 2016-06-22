{CompositeDisposable} = require 'atom'

module.exports =
class ItermExecute
  @subscriptions: null
  @editor: null
  @projectPath: null

  @activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor', 'iterm-execute:run-ruby-test': => @runRubyTest()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'iterm-execute:run-ruby-current-line-test': => @runCurrentTestContext()

    @editor = -> atom.workspace.getActiveTextEditor()
    @projectPath = -> atom.workspace.project.getPaths()[0]

  @runRubyTest: ->
    filePath = @currentActiveFilePath()
    @executeCode("bundle exec ruby -I test #{filePath}")

  @runCurrentTestContext: ->
    currentRowNumber = @editor().getCursorScreenPosition().row
    rows = @editor().getText().split("\n")

    if testTitle = @findTestTitleIn(rows, currentRowNumber)
      filePath = @currentActiveFilePath()
      @executeCode("bundle exec ruby -I test #{filePath} -n /#{@formatTestTitle(testTitle)}/")

  @findTestTitleIn: (rows, currentRowNumber) ->
    validRows = rows.slice(0, currentRowNumber+1).reverse()

    for row in validRows
      if row.match(/test .+ do/)
        if testTitle = row.match(/['|"](.+)['|"]/)?[1]
          return testTitle

  @formatTestTitle: (title) ->
    title.replace(/#/g, "")
         .replace(/\ /g, "_")
         .replace(/!/g, "\\!")

  @deactivate: ->
    @subscriptions.dispose()

  @currentActiveFilePath: ->
    fullFilePath = @editor().getPath()

    fullFilePath.replace("#{@projectPath()}/", "")


  @executeCode: (code) ->
    osascript = require 'node-osascript'

    command = []
    command.push 'tell application "iTerm2"'
    command.push '	tell current session of first window'
    command.push '		activate current session'
    command.push '		write text code'
    command.push '	end tell'
    command.push 'end tell'
    command = command.join('\n')

    osascript.execute command, {code: code}, (error, result, raw) ->
      if error
        console.error(error)
