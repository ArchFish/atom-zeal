dash = require('../lib/zeal')

describe "zeal", ->
  it "should open zeal", ->
    waitsForPromise ->
      atom.workspace.open('test.hs').then (editor) ->
        view = atom.views.getView(editor)

        editor.setCursorBufferPosition({ row: 1, column: 6 })

        new Promise (resolve, reject) ->
          zeal.exec = (cmd) ->
            expect(cmd).toEqual('open -g "zeal-plugin://query=.SetFlags"')
            resolve()

          zeal.shortcut(true)

  it "should open zeal with background", ->
    waitsForPromise ->
      atom.workspace.open('test.hs').then (editor) ->
        view = atom.views.getView(editor)

        editor.setCursorBufferPosition({ row: 1, column: 6 })

        new Promise (resolve, reject) ->
          zeal.exec = (cmd) ->
            expect(cmd).toEqual('open -g "zeal-plugin://query=.SetFlags&prevent_activation=true"')
            resolve()

          zeal.shortcut(true, true)
