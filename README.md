# autodoc

This library attempts to generate docs for jsonnet code.

> [!CAUTION]
> This is an experimental library.

## Functions

### func documentableFields

```jsonnet
documentableFields(object)
```

Find fields that can be documented.
This essentially filters out calculated fields in the form of `[<expr>]`.

### func fieldName

```jsonnet
fieldName(field)
```

Get the field name, this assumes fieldname.type is either `string` or `id`.
Use `documentableFields()` to filter these out.

### func filterAnonymousFunctionFields

```jsonnet
filterAnonymousFunctionFields(fields)
```

### func filterFunctionFields

```jsonnet
filterFunctionFields(fields)
```

### func filterObjectFields

```jsonnet
filterObjectFields(fields)
```

### func findRootObject

```jsonnet
findRootObject(ast)
```

### func getCommentBeforeLine

```jsonnet
getCommentBeforeLine(lineNr)
```

### func render

```jsonnet
render(depth=0)
```

### func renderAnonymousFunction

```jsonnet
renderAnonymousFunction(field, parents, depth)
```

### func renderFieldFunction

```jsonnet
renderFieldFunction(field, parents, depth)
```

### func renderFunction

```jsonnet
renderFunction(name, signature, docstring, depth)
```

### func renderObject

```jsonnet
renderObject(object, parents=[], depth)
```

