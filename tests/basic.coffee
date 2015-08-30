Tinytest.add 'ComputedFields - Basic', (test) ->
  posts = new Mongo.Collection null
  posts.computedFields.add 'updateCount', (post) ->
    @set (post.updateCount or 0) + 1
  postId = posts.insert name: 'test'
  posts.update postId, $set: name: 'passed'

  post = posts.findOne postId
  test.equal post.updateCount, 2

Tinytest.add 'computedFields - external dependencies', (test) ->
  posts = new Mongo.Collection null
  authors = new Mongo.Collection null

  authors.computedFields.add('postCount').addDependency posts,
    findId: (post) -> post.authorId
    update: (author, post) ->
      if @isInsert or @previous.authorId isnt author._id
        inc = 1
      else if @isRemove or
      (@previous.authorId is author._id and post.authorId isnt author._id)
        inc = -1
      @set (author.postCount or 0) + inc

  authorId = authors.insert name: 'max'
  postId = posts.insert
    name: 'test'
    authorId: authorId
  author = authors.findOne authorId
  test.equal author.postCount, 1

  postId2 = posts.insert
    name: 'test2'
    authorId: authorId
  author = authors.findOne authorId
  test.equal author.postCount, 2

  posts.update postId, $set: test: 1
  author = authors.findOne authorId
  test.equal author.postCount, 2

  posts.update postId, $set: authorId: 'test123'
  author = authors.findOne authorId
  test.equal author.postCount, 1

  posts.remove postId2
  author = authors.findOne authorId
  test.equal author.postCount, 0

#Test API:
#test.isFalse(v, msg)
#test.isTrue(v, msg)
#test.equalactual, expected, message, not
#test.length(obj, len)
#test.include(s, v)
#test.isNaN(v, msg)
#test.isUndefined(v, msg)
#test.isNotNull
#test.isNull
#test.throws(func)
#test.instanceOf(obj, klass)
#test.notEqual(actual, expected, message)
#test.runId()
#test.exception(exception)
#test.expect_fail()
#test.ok(doc)
#test.fail(doc)
#test.equal(a, b, msg)
