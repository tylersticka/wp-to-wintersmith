to_markdown = require('to-markdown').toMarkdown
moment = require 'moment'
YAML = require 'yamljs'
urlRegex = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
urlSplit = "wp-content/uploads"

Parser = ->
  return this

Parser.prototype.parse = (post) ->
  post_content = to_markdown post['content:encoded'][0]
  post_uploads = []
  (post_content.match(urlRegex) or []).forEach (match) ->
    if match.indexOf(urlSplit) isnt -1
      post_uploads.push
        original: match
        relative: match.split(urlSplit)[1]
  post_comments = []
  if post["wp:comment"]
    for comment in post["wp:comment"] when comment["wp:comment_approved"][0] is '1'
      post_comment =
        id: parseInt comment["wp:comment_id"][0], 10
        author: comment["wp:comment_author"][0]
        date: moment.utc(comment["wp:comment_date"][0] + '-08:00').format("YYYY-MM-DDTHH:mm:ssZ")
        contents: comment["wp:comment_content"][0]
      if comment["wp:comment_author_url"] then post_comment.url = comment["wp:comment_author_url"][0]
      post_comments.push post_comment
  parsed =
    title: post.title[0]#.replace(':', '')
    filename: post["wp:post_name"]
    date: moment.utc(post.pubDate, "ddd, D MMM YYYY HH:mm:ss ZZ").format("YYYY-MM-DDTHH:mm:ssZ")
    content: post_content
    uploads: post_uploads
  if post_comments.length
    parsed.comments =
      YAML: YAML.stringify { comments: post_comments }, 4, 2
  return parsed

Parser.prototype.globals = (input) ->
  obj = input.rss
  channel = obj.channel[0]
  authors = channel['wp:author']
  parsed_authors = []
  for author in authors when author['wp:author_display_name'][0] isnt 'legacy'
    fullname = "#{author['wp:author_first_name']} #{author['wp:author_last_name']}"
    parsed_authors.push
      email: author['wp:author_email'][0]
      name: fullname
      shortname: fullname.split(' ').join('').toLowerCase()
  parsed =
    authors: parsed_authors

Parser.prototype.posts = (input) ->
  posts = []
  for post in input.rss.channel[0].item
    if post['wp:post_type'][0] is 'post' and post['wp:status'][0] is 'publish'
      posts.push post
    # console.log post['wp:post_type'][0]
  # posts.push post for post in input.rss.channel[0].item when input.rss.channel[0].item['wp::post_type'][0] is 'post'
  return posts

Parser.prototype.wrapper = (input) ->
  posts = @posts input
  parsed_posts = []
  parsed_posts.push(@parse(post)) for post in posts
  globals = @globals input
  parsed =
    posts: parsed_posts
    globals: globals

module.exports = new Parser()
