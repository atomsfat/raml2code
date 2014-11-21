deref = require('deref')();
util = {}
util.getUriParameter = (resource, annotation)->
  uriParameters = []
  for key of resource.uriParameters
    p = resource.uriParameters[key]
    uriParameters.push util.mapProperty(p, key, annotation)
  uriParameters

util.getQueryparams = (queryParams, annotation)->
  params = []
  for key of queryParams
    p = queryParams[key]
    params.push util.mapProperty(p, key, annotation)
  params


util.mapProperty = (property, name, annotation)->
  p = {}
  p.name = name
  p.comment =  property.description
  switch property.type
    when 'array'
#      console.log "--------------", property
      p.type = "List"
#      console.log "--------------", property.items['$ref']
#      ref = util.capitalize(ref)
#      console.log "ref->". ref

#      p.name = "items"
    when 'object'
      console.log "=====================1"
      console.log "OBJECT", property
      console.log "=====================2"
      if property.properties

        if property.title
          p.type = util.capitalize(property.title)
        else
          p.type = 'FOO'

      else
        p.type = 'Object'
    when 'string' then p.type = "String"
    when 'boolean' then p.type = "Boolean"
    when 'number' then p.type = "Double"
    when 'integer' then p.type = "Integer"
    when 'object' then p.type = "Map"

  p.kind = annotation + "(\"#{p.name}\")"
  p



util.parseResource = (resource, parsed, annotations,  parentUri = "", parentUriArgs = []) ->

  for m in resource.methods
    methodDef = {}
    methodDef.uri = parentUri + resource.relativeUri
    uriArgs = util.getUriParameter(resource, annotations.path)
    methodDef.args = parentUriArgs.concat(uriArgs)
    methodDef.args = methodDef.args.concat(util.getQueryparams(m.queryParameters, annotations.query))
    request = util.parseSchema(m.body,  "#{methodDef.uri} body" )
    respond = util.parseSchema(util.getBestValidResponse(m.responses).body,  "#{methodDef.uri} response" )
    if request.title
      methodDef.args = methodDef.args ? []
      methodDef.args.push {'kind': annotations.body, 'type': request.title, 'name': request.title.toLowerCase()}

    methodDef.request = request.title ? null
    methodDef.respond = respond.title
    methodDef.annotation = m.method.toUpperCase()
    methodDef.name = m.method + resource.displayName
    methodDef.displayName = resource.displayName
    parsed.push methodDef
  if resource.resources
    for innerResource in resource.resources
      util.parseResource(innerResource, parsed, annotations, methodDef.uri, uriArgs)
  undefined


util.parseSchema = (body, meta = '') ->
  schema = {}
  if body and body['application/json']
    try
      schema = JSON.parse(body['application/json'].schema)
    catch e
      console.log "-----JSON ERROR on #{meta}---------"
      console.log body['application/json'].schema
      throw e

  schema

util.getBestValidResponse = (responses) ->
  response = responses["304"] ?
    response = responses["204"] ?
    response = responses["201"] ?
    response = responses["200"] ?
    response

util.capitalize = (str)->
  str.charAt(0).toUpperCase() + str.slice(1)

util.sanitize = (str)->
  aux = str.split(".")
  res = ''
  aux.forEach (it)->
    res += util.capitalize(it)
  res

module.exports = util
