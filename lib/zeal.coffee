basename = require('path').basename
exec = require('child_process').exec
platform = require('process').platform
grammarMap = require('./grammar-map')
filenameMap = require('./filename-map')

plugin = module.exports =
  # Use an empty config by default since Atom fails to populate the settings
  # view corretly with pre-defined properties.
  config:
    grammars:
      type: 'object'
      properties: {}
    filenames:
      type: 'object'
      properties: {}

  # Override `exec` for testing.
  exec: exec

  activate: () ->
    atom.commands.add('atom-text-editor', {
      'zeal:shortcut': () => @shortcut(true, false),
      'zeal:shortcut-background': () => @shortcut(true, true),
      'zeal:shortcut-alt': () => @shortcut(false, false),
      'zeal:shortcut-alt-background': () => @shortcut(false, true),
      'zeal:context-menu': () => @shortcut(true, false)
    })

  shortcut: (sensitive, background) ->
    editor = atom.workspace.getActiveTextEditor()

    return if !editor

    selection = editor.getLastSelection().getText()

    callback = (error) =>
      atom.notifications.addError('Unable to launch Zeal', {
        dismissable: true,
        detail: error.message
      }) if error

    if selection
      return plugin.search(selection, sensitive, background, callback)

    return plugin.search(editor.getWordUnderCursor(), sensitive, background, callback)

  search: (string, sensitive, background, cb) ->
    activeEditor = atom.workspace.getActiveTextEditor()

    if sensitive and activeEditor
      path = activeEditor.getPath()
      language = activeEditor.getGrammar().name

    cmd = @getCommand(string, path, language, background)

    # Exec is used because spawn escapes arguments that contain double-quotes
    # and replaces them with backslashes. This interferes with the ability to
    # properly create the child process in windows, since windows will barf
    # on an ampersand that is not contained in double-quotes.
    #  /home/weihl/ruby,rubygems,rails:zeal --query=find
    plugin.exec(cmd, cb)

  getCommand: (string, path, language, background) ->
    uri = @getZealURI(string, path, language, background)

    if platform == 'win32'
      return 'cmd.exe /c start "" "' + uri + '"'

    if platform == 'linux'
      return uri

    return 'open -g "' + uri + '"'

  getKeywordString: (path, language) ->
    keys = []

    if path
      filename = basename(path).toLowerCase()
      filenameConfig = atom.config.get('zeal.filenames') || {}
      keys = keys.concat(filenameConfig[filename] || filenameMap[filename] || [])

    if language
      grammarConfig = atom.config.get('zeal.grammars') || {}
      keys = keys.concat(grammarConfig[language] || grammarMap[language] || [])

    return keys.map(encodeURIComponent).join(',') if keys.length

  getZealURI: (string, path, language, background) ->
    link = 'zeal --query='
    keywords = @getKeywordString(path, language)

    if keywords
      link += keywords + ':' + encodeURIComponent(string)

    if background
      link += '&prevent_activation=true'

    return link
