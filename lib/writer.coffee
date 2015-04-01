fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
mustache = require 'mustache'
moment = require 'moment'

mode = 0o0775

Writer = ->
  return this

Writer.prototype.write_authors = (authors) ->
  mkdirp.sync './contents/authors', mode
  fs.writeFileSync("./contents/authors/#{author.shortname}.json", JSON.stringify(author)) for author in authors when author.name isnt ' '

Writer.prototype.write_content = (obj) ->
  template = fs.readFileSync('./lib/templates/article.mustache').toString()
  for post in obj.posts
    post.author = obj.globals.authors[0].shortname
    post.date = moment(new Date(post.date)).utc().format("YYYY-MM-DD")
    post_filename = post.filename;
    post_folder = "./contents/articles/#{post_filename}"
    mkdirp.sync(post_folder, mode)

    # transitioning uploads
    post.uploads.forEach (url) ->
      # copy file relative to post
      base_name = path.basename url.relative
      local_file = fs.readFileSync "./uploads#{url.relative}"
      fs.writeFileSync "#{post_folder}/#{base_name}", local_file
      # replace occurrences with relative link instead
      search_regex = new RegExp url.original, 'g'
      post.content = post.content.replace search_regex, base_name

    post = mustache.render template, post
    fs.writeFileSync "#{post_folder}/index.md", post

module.exports = new Writer()
