local parser = import './vendor/github.com/Duologic/jsonnet-parser/parser.libsonnet';
local a = import './vendor/github.com/crdsonnet/astsonnet/schema.libsonnet';

local md = {
  header(string, depth):
    [
      std.join('', ['#' for i in std.range(1, depth)])
      + ' '
      + string
      + '\n',
    ],
  code(string):
    [
      '```',
      string,
      '```',
      '',
    ],
  paragraph(string):
    if string != ''
    then [string + '\n']
    else [],
};

// This library attempts to generate docs for jsonnet code.
//
// > [!CAUTION]
// > This is an experimental library.
function(file) {
  file: file,
  parsed: parser.new(file).parse(),

  render(depth=0):
    local object = self.findRootObject(self.parsed);
    std.join(
      '\n',
      self.renderObject(object, depth=depth + 1),
    ),

  findRootObject(ast):
    if ast.type == 'object'
    then ast
    else if 'expr' in ast
    then self.findRootObject(ast.expr)
    else error 'no object found',

  renderObject(object, parents=[], depth):
    local fields =
      self.documentableFields(object);

    local filteredFields =
      self.filterFunctionFields(fields)
      + self.filterAnonymousFunctionFields(fields)
      + self.filterObjectFields(fields);

    local fieldNames =
      std.sort(
        std.map(self.fieldName, filteredFields)
      );

    local constructorFieldNames = std.sort(
      std.filter(
        function(name)
          std.startsWith(name, 'new'),
        fieldNames,
      )
    );

    // 1. prioritize constructor fields
    // 2. sort others alphabetically
    local sortedFields =
      std.sort(
        filteredFields,
        function(field)
          local name = self.fieldName(field);
          if std.member(constructorFieldNames, name)
          then std.find(name, constructorFieldNames)[0]
          else
            std.length(constructorFieldNames)
            + std.find(name, fieldNames)[0] + 1
      );

    std.foldl(
      function(acc, field)
        acc
        + (
          if field.type == 'field_function'
          then self.renderFieldFunction(field, parents, depth + 1)
          else if field.expr.type == 'anonymous_function'
          then self.renderAnonymousFunction(field, parents, depth + 1)
          else if field.expr.type == 'object'
          then self.renderObject(field.expr, parents + [self.fieldName(field)], depth + 1)
          else error 'unexpected field type'
        ),
      sortedFields,
      if parents == []
      then
        md.paragraph(self.getCommentBeforeLine(object.line))
        + md.header('Functions', depth)
      else
        md.header('obj ' + std.join('.', parents), depth)
        + md.paragraph(self.getCommentBeforeLine(object.line))
    ),

  // Find fields that can be documented.
  // This essentially filters out calculated fields in the form of `[<expr>]`.
  documentableFields(object):
    std.filter(
      function(member)
        std.member(['id', 'string'], member.fieldname.type),
      std.get(object, 'members', []),
    ),

  // Get the field name, this assumes fieldname.type is either `string` or `id`.
  // Use `documentableFields()` to filter these out.
  fieldName(field):
    field.fieldname[field.fieldname.type],

  filterFunctionFields(fields):
    std.filter(
      function(field)
        field.type == 'field_function',
      fields,
    ),

  filterAnonymousFunctionFields(fields):
    std.filter(
      function(field)
        field.expr.type == 'anonymous_function',
      fields,
    ),

  filterObjectFields(fields):
    std.filter(
      function(field)
        field.type == 'field'
        && field.expr.type == 'object',
      fields,
    ),

  renderFieldFunction(field, parents, depth):
    local name = std.join('.', parents + [self.fieldName(field)]);
    self.renderFunction(
      name,
      if 'params' in field
      then name + '(' + a.objectToString(field.params) + ')'
      else name + '()',
      self.getCommentBeforeLine(field.line),
      depth,
    ),

  renderAnonymousFunction(field, parents, depth):
    local name = std.join('.', parents + [self.fieldName(field)]);
    self.renderFunction(
      name,
      if 'params' in field.expr
      then name + '(' + a.objectToString(field.expr.params) + ')'
      else name + '()',
      self.getCommentBeforeLine(field.line),
      depth,
    ),

  renderFunction(name, signature, docstring, depth):
    md.header('func ' + name, depth)
    + md.code(signature)
    + md.paragraph(docstring),

  getCommentBeforeLine(lineNr):
    local lines = std.split(self.file, '\n');
    local before =
      std.map(
        function(str)
          std.stripChars(str, ' '),
        std.reverse(lines[0:lineNr - 1])
      );

    local comments =
      local aux(index=0, return=[]) =
        if index < std.length(before)
           && (std.startsWith(before[index], '//')
               || std.startsWith(before[index], '#'))
        then aux(index + 1, return + [before[index]])
        else return;
      aux();

    std.join(
      '\n',
      std.map(
        function(str)
          if std.startsWith(str, '// ')
          then str[3:]
          else if std.startsWith(str, '//')
          then str[2:]
          else if std.startsWith(str, '# ')
          then str[2:]
          else if std.startsWith(str, '#')
          then str[1:]
          else str,
        std.reverse(comments)
      ),
    ),
}
