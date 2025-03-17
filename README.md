# Autodoc

Autodoc can generate documentation for Jsonnet code, optionally annotated with code comments.

While any comments are processed, the goal is to parse and pretty print [JSDoc](https://jsdoc.app/) annotations.

> [!CAUTION]
> This is an experimental library.

## Index

* [func new](func-new)
  * [func new().render](func-newrender)
  * [func new().generateIndex](func-newgenerateindex)
  * [func new().findRootObject](func-newfindrootobject)
  * [func new().renderObject](func-newrenderobject)
  * [func new().documentableFields](func-newdocumentablefields)
  * [func new().fieldName](func-newfieldname)
  * [func new().filterFunctionFields](func-newfilterfunctionfields)
  * [func new().filterAnonymousFunctionFields](func-newfilteranonymousfunctionfields)
  * [func new().filterObjectFields](func-newfilterobjectfields)
  * [func new().renderFieldFunction](func-newrenderfieldfunction)
  * [func new().renderAnonymousFunction](func-newrenderanonymousfunction)
  * [func new().renderFunction](func-newrenderfunction)
  * [func new().getCommentBeforeLine](func-newgetcommentbeforeline)

## Fields

### func new

```jsonnet
new(title, file)
```

`new` creates a new autodoc parser
@constructor
@param {string} - title
@param {string} - file (example: `imporstr './main.libsonnet'`)
@returns {object}

#### func new().render

```jsonnet
render(depth=0)
```

`render` processes the file into Markdown
@param {number} - [depth=0]
@returns {string}

#### func new().generateIndex

```jsonnet
generateIndex(lines)
```

#### func new().findRootObject

```jsonnet
findRootObject(ast)
```

#### func new().renderObject

```jsonnet
renderObject(object, parents=[], depth, noHeader=false)
```

#### func new().documentableFields

```jsonnet
documentableFields(object)
```

Find fields that can be documented.
This essentially filters out calculated fields in the form of `[<expr>]`.

#### func new().fieldName

```jsonnet
fieldName(field)
```

Get the field name, this assumes fieldname.type is either `string` or `id`.
Use `documentableFields()` to filter these out.

#### func new().filterFunctionFields

```jsonnet
filterFunctionFields(fields)
```

#### func new().filterAnonymousFunctionFields

```jsonnet
filterAnonymousFunctionFields(fields)
```

#### func new().filterObjectFields

```jsonnet
filterObjectFields(fields)
```

#### func new().renderFieldFunction

```jsonnet
renderFieldFunction(field, parents, depth)
```

#### func new().renderAnonymousFunction

```jsonnet
renderAnonymousFunction(field, parents, depth)
```

#### func new().renderFunction

```jsonnet
renderFunction(name, signature, docstring, depth)
```

#### func new().getCommentBeforeLine

```jsonnet
getCommentBeforeLine(lineNr)
```
