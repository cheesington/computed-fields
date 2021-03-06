class ComputedFields
  constructor: (@collection) -> @fields = {}
  add: (name, updateMethod) ->
    check name, String
    check updateMethod, Match.Optional Function
    unless @fields[name]?
      @fields[name] = new ComputedField @collection, name, updateMethod
    return @fields[name]

  get: (name) ->
    check name, String
    @fields[name] or @add(name)

  rebuild: ->
    collections = []
    for name, field of @fields
      collections.push field.collection unless field.collection in collections
      for dependency in field._dependencies
        unless dependency.collection in collections
          collections.push dependency.collection

    for collection in collections
      collection.find().forEach (doc) =>
        for name, field of @fields
          if field.collection is collection and field.updateMethod?
            thisValue = field._getThis null, doc, null, [], 'insert'
            field.updateMethod.call thisValue, doc
          for dependency in field._dependencies when dependency.collection is collection
            if fieldDocs = dependency.findDocs doc
              for fieldDoc in fieldDocs
                thisValue = field._getThis null, fieldDoc, null, [], 'insert'
                dependency.update.call thisValue, fieldDoc, doc




class ComputedField
  constructor: (@collection, @name, @updateMethod) ->
    field = this
    @_dependencies = []
    return unless @updateMethod?
    addHooks @collection, (type, userId, doc, fieldNames) ->
      thisValue = field._getThis this, doc, userId, fieldNames, type
      field.updateMethod.call thisValue, @transform()

  _getThis: (hook, doc, userId, fieldNames, type) ->
    unless hook?
      hook =
        transform: (obj) -> obj
        previous: {}

    isUpdate: type is 'update'
    isInsert: type is 'insert'
    isRemove: type is 'remove'
    previous: hook.transform hook.previous
    userId: userId
    fieldNames: fieldNames
    computedField: @name
    set: (value) =>
      $set = {}
      $set[@name] = value
      @collection.direct.update doc._id, {$set}
    unset: =>
      $unset = {}
      $unset[@name] = 1
      @collection.direct.update doc._id, {$unset}

  rebuild: ->
    field = this
    if @updateMethod?
      @collection.find().forEach (doc) ->
        thisValue = field._getThis null, doc, null, [], 'insert'
        field.updateMethod.call thisValue, doc

    for dependency in @_dependencies
      dependency.collection.find().forEach (doc) ->
        return unless fieldDocs = dependency.findDocs doc

        for fieldDoc in fieldDocs
          thisValue = field._getThis null, fieldDoc, null, [], 'insert'
          dependency.update.call thisValue, fieldDoc, doc

  addDependency: (collection, options) ->
    check collection, Match.Any
    check options,
      findId: Function
      update: Function
      updateOnPrevious: Match.Optional Boolean

    options.updateOnPrevious = true unless options.updateOnPrevious?

    field = this
    findDocs = (doc) ->
      ids = options.findId(doc)
      ids = [ids] unless _.isArray ids
      docs = for _id in ids
        field.collection.findOne _id: _id
      docs = _.without docs, undefined, null
      return if docs.length is 0
      return docs

    @_dependencies.push _.extend _.clone(options),
      collection: collection
      findDocs: findDocs

    addHooks collection, (type, userId, doc, fieldNames) ->
      callUpdate = (fieldDocs) ->
        for fieldDoc in fieldDocs
          thisValue = field._getThis this, fieldDoc, userId, fieldNames, type
          options.update.call thisValue, fieldDoc, @transform()

      if doc? and currentDocs = findDocs @transform()
        callUpdate.call this, currentDocs

      return unless options.updateOnPrevious

      if @previous? and previousDocs = findDocs @transform(@previous)
        callUpdate.call this, previousDocs
    return this

  simple: (collection, fieldName, setMethod) ->
    field = this
    @addDependency collection,
      findId: (externalDoc) -> externalDoc[fieldName]
      update: (doc, externalDoc) ->
        if @isInsert or @previous[fieldName] isnt doc._id
          increment = 1
        else if @isRemove or
        (@previous[fieldName] is doc._id and externalDoc[fieldName] isnt doc._id)
          increment = -1
        else return

        _this = _.extend this, increment: increment
        value = setMethod.call _this, doc, externalDoc
        @set value
    return this
  increment: (collection, fieldName, incMethod) ->
    field = this
    @simple collection, fieldName, (doc, externalDoc) ->
      current = _.reduce field.name.split("."), (field, part) ->
        field && field[part]
      , doc
      (current or 0) + incMethod.call this, doc, externalDoc
    return this
  count: (collection, fieldName) ->
    @increment collection, fieldName, (doc, externalDoc) -> @increment

addHooks = (collection, method) ->
  callMethod = (type) -> (userId, doc, fieldNames) ->
    method.call this, type, userId, doc, fieldNames
  collection.after.insert callMethod 'insert'
  collection.after.update callMethod 'update'
  collection.after.remove callMethod 'remove'

CollectionExtensions.addExtension (name, options) ->
  @computedFields = new ComputedFields this
