ItermExecute = require '../lib/iterm-execute'

describe "ItermExecute", ->
  [workspaceElement, activationPromise, iTermExecute] = []

  beforeEach ->
    activationPromise = atom.packages.activatePackage('iterm-execute')
    workspaceElement  = atom.views.getView(atom.workspace)

    waitsForPromise ->
      activationPromise
    atom.commands.dispatch workspaceElement, 'iterm-execute:run-ruby-test'

    mockItermExecute()

  mockItermExecute = ->
    spyOn(ItermExecute, 'projectPath').andReturn("/path/to/project")
    spyOn(ItermExecute, 'executeCode').andCallFake().andReturn(->)

  describe "when iterm-execute:run-ruby-test runs", ->

    it "get current file path and call execute code", ->
      spyOn(ItermExecute, 'editor').andReturn(getPath: -> "/path/to/project/to/file.rb")

      ItermExecute.runRubyTest()
      expect(ItermExecute.executeCode).toHaveBeenCalledWith("bundle exec ruby -I test to/file.rb")

  describe "when iterm-execute:run-ruby-current-line-test runs", ->
    it "execute test of the context of the cursor", ->
      spyOn(ItermExecute, 'editor').andReturn(
        getPath: -> "/path/to/project/to/file.rb"
        getCursorScreenPosition: ->
          row: 5
        getText: ->
          '#ruby comment\n
            \n
             test "#index should do something" do\n
                ruby_code\n
                get "something"\n
                5.times do  # << cursor is here\n
                  something\n
                end'
        )

      ItermExecute.runCurrentTestContext()
      expect(ItermExecute.executeCode).toHaveBeenCalledWith("bundle exec ruby -I test to/file.rb -n /index_should_do_something/")

    it "executes test title if the cursor is on the same line as the title", ->
      spyOn(ItermExecute, 'editor').andReturn(
        getPath: -> "/path/to/project/to/file.rb"
        getCursorScreenPosition: ->
          row: 2
        getText: ->
          '#ruby comment\n
            \n
             test "#index should do something" do\n
                ruby_code\n
                get "something"\n
                5.times do  # << cursor is here\n
                  something\n
                end'
        )

      ItermExecute.runCurrentTestContext()
      expect(ItermExecute.executeCode).toHaveBeenCalledWith("bundle exec ruby -I test to/file.rb -n /index_should_do_something/")

    it "executes test title for single quotes", ->
      spyOn(ItermExecute, 'editor').andReturn(
        getPath: -> "/path/to/project/to/file.rb"
        getCursorScreenPosition: ->
          row: 2
        getText: ->
          "#ruby comment\n
            \n
             test '#index should do something' do\n
                ruby_code\n
                get 'something'\n
                5.times do
                  something\n
                end"
        )

      ItermExecute.runCurrentTestContext()
      expect(ItermExecute.executeCode).toHaveBeenCalledWith("bundle exec ruby -I test to/file.rb -n /index_should_do_something/")

    it "it doesnt try to execute iTerm if no test title is found", ->
      spyOn(ItermExecute, 'editor').andReturn(
        getPath: -> "/path/to/project/to/file.rb"
        getCursorScreenPosition: ->
          row: 2
        getText: ->
          '#ruby comment\n
           \n
           ruby_code\n
           get "something"\n
           5.times do  # << cursor is here\n
             something\n
           end'
        )

      ItermExecute.runCurrentTestContext()
      expect(ItermExecute.executeCode.calls.length).toEqual(0)

    it "it replaces ! with \! for test titles that include !", ->
      spyOn(ItermExecute, 'editor').andReturn(
        getPath: -> "/path/to/project/to/file.rb"
        getCursorScreenPosition: ->
          row: 2
        getText: ->
          "#ruby comment\n
            \n
             test '#index yeah! do something' do\n
                ruby_code\n
                get 'something'\n
                5.times do
                  something\n
                end"
        )

      ItermExecute.runCurrentTestContext()
      expect(ItermExecute.executeCode).toHaveBeenCalledWith("bundle exec ruby -I test to/file.rb -n /index_yeah\\!_do_something/")
