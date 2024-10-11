# autodoc

This library attempts to generate docs for jsonnet code.

> [!CAUTION]
> This is an experimental library.

## Functions

### func documentableFields

```
documentableFields(object)
```

Find fields that can be documented.
This essentially filters out calculated fields in the form of `[<expr>]`.

### func fieldName

```
fieldName(field)
```

Get the field name, this assumes fieldname.type is either `string` or `id`.
Use `documentableFields()` to filter these out.

### func filterAnonymousFunctionFields

```
filterAnonymousFunctionFields(fields)
```

### func filterFunctionFields

```
filterFunctionFields(fields)
```

### func filterObjectFields

```
filterObjectFields(fields)
```

### func findRootObject

```
findRootObject(ast)
```

### func getCommentBeforeLine

```
getCommentBeforeLine(lineNr)
```

### func render

```
render(depth=0)
```

### func renderAnonymousFunction

```
renderAnonymousFunction(field, parents, depth)
```

### func renderFieldFunction

```
renderFieldFunction(field, parents, depth)
```

### func renderFunction

```
renderFunction(name, signature, docstring, depth)
```

### func renderObject

```
renderObject(object, parents=[], depth)
```

