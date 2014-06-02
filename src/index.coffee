_ = require('underscore')
path = require('path')
fs = require('fs')
yaml = require('js-yaml')
cson = require('cson')

extensions =
  json:
    parse: (content) -> JSON.parse(content)
  yml:
    parse: (content) -> yaml.load(content)
  yaml:
    parse: (content) -> yaml.load(content)
  cson:
    parse: (content) -> cson.parseSync(content)

load_config = (opts) ->
  configs = {}
  dir = path.resolve(process.cwd(), opts.path)
  load_files(dir).forEach (file) ->
    config = extensions[file.extension].parse(file.content)
    configs[file.name] = get_environment(config)
  configs

get_environment = (config) ->
  env = process.env.NODE_ENV or 'development'
  env_config = config[env] or {}
  _.defaults(env_config, config['default'])

inject_variables = (file) ->
  file.replace /#\{(.+)\}/g, (match, code) ->
    code = code.split('.')
    base = new Function("return #{code[0]}")()
    code.shift()
    for variable in code
      base = base[variable]
    base = null unless base?
    base

load_files = (path) ->
  regex = new RegExp("\\.(#{Object.keys(extensions).join('|')})$", 'i')
  (fs.readdirSync(path).filter (file) -> regex.test(file))
    .map (file) ->
      [__, name, extension] = /^(.+)\.+(.+)$/.exec(file)
      name: name.toLowerCase().replace(/\./g, '_')
      extension: extension.toLowerCase()
      content: inject_variables(fs.readFileSync("#{path}/#{file}", 'utf-8'))

module.exports = (opts = {})->
  options =
    path: './config'
  opts = _.defaults(opts, options)
  load_config(opts)