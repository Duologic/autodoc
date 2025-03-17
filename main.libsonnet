local parser = import 'github.com/Duologic/jsonnet-parser/parser.libsonnet';
local a = import 'github.com/crdsonnet/astsonnet/schema.libsonnet';

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
      '```jsonnet',
      string,
      '```',
      '',
    ],
  paragraph(string):
    if string != ''
    then [string + '\n']
    else [],
};

// Autodoc can generate documentation for Jsonnet code, optionally annotated with code comments.
//
// While any comments are processed, the goal is to parse and pretty print [JSDoc](https://jsdoc.app/) annotations.
//
// > [!CAUTION]
// > This is an experimental library.
{
  // `new` creates a new autodoc parser
  // @constructor
  // @param {string} - title
  // @param {string} - file (example: `imporstr './main.libsonnet'`)
  // @returns {object}
  new(title, file): {
    file: file,
    parsed: parser.new(file).parse(),

    // `render` processes the file into Markdown
    // @param {number} - [depth=0]
    // @returns {string}
    render(depth=0):
      local object = self.findRootObject(self.parsed);
      local lines = self.renderObject(object, depth=depth + 2);

      local indexedLines = std.mapWithIndex(function(index, line) { index: index, line: line }, lines);
      local titleLines = std.filter(function(l) std.startsWith(l.line, '#'), indexedLines);
      local secondTitleIndex = titleLines[1].index;

      local index = self.generateIndex(lines[secondTitleIndex:]);
      std.join(
        '\n',
        md.header(title, depth + 1)
        + lines[0:secondTitleIndex - 1]
        + md.header('Index', depth + 2)
        + index
        + lines[secondTitleIndex - 1:]
      ),

    generateIndex(lines):
      local titles =
        std.filter(
          function(line) std.startsWith(line, '#'),
          lines
        );

      local links =
        std.foldr(
          std.map,
          [
            function(title) '#' + title,
            function(title) std.join('', title),  // join array again
            function(title)
              std.filter(
                // drop punctuation marks except dashes
                function(c)
                  c == '-'
                  || c == '_'  // kept by GitHub Markdown
                  // keep numbers
                  || (std.codepoint(c) >= 48
                      && std.codepoint(c) <= 57)
                  // keep lowercase ascii
                  || (std.codepoint(c) >= 97
                      && std.codepoint(c) <= 122),
                title
              ),
            std.stringChars,  // make array of word
            std.asciiLower,
            function(title) std.strReplace(title, ' ', '-'),
            function(title) std.stripChars(title, ' '),
            function(title) std.lstripChars(title, '#'),
          ],
          titles
        );

      local firstTitle = titles[0];
      local firstTitleWithoutPrefix = std.lstripChars(firstTitle, '# ');
      local firstTitleDepth = std.length(firstTitle) - std.length(firstTitleWithoutPrefix);

      std.mapWithIndex(
        function(index, title)
          local titleWithoutPrefix = std.lstripChars(title, '# ');
          local linedepth = std.length(title) - std.length(titleWithoutPrefix);
          std.join('', [' ' for _ in std.range(0, (linedepth * 2) - (firstTitleDepth * 2) - 1)]) +
          '* [' + std.stripChars(titleWithoutPrefix, '\n') + '](%s)' % links[index]
        , titles
      ) + [''],

    findRootObject(ast):
      if ast.type == 'object'
      then ast
      else if 'expr' in ast
      then self.findRootObject(ast.expr)
      else error 'no object found',

    renderObject(object, parents=[], depth, noHeader=false):
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

      // prioritize constructor fields
      local sortedFields =
        std.filter(
          function(field)
            std.member(constructorFieldNames, self.fieldName(field)),
          filteredFields,
        )
        + std.filter(
          function(field)
            !std.member(constructorFieldNames, self.fieldName(field)),
          filteredFields,
        );

      std.foldl(
        function(acc, field)
          acc
          + (
            if std.get(field, 'h', '') == '::'
            then []
            else if field.type == 'field_function'
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
          md.paragraph(self.getCommentBeforeLine(object.location.line))
          + md.header('Fields', depth)
        else if noHeader
        then []
        else
          md.header('obj ' + std.join('.', parents), depth)
          + md.paragraph(self.getCommentBeforeLine(object.location.line))
      ),

    // Find fields that can be documented.
    // This essentially filters out calculated fields in the form of `[<expr>]`.
    documentableFields(object):
      std.filter(
        function(member)
          std.objectHas(member, 'fieldname')
          && std.member(['id', 'string'], member.fieldname.type)
          && !std.startsWith(member.fieldname[member.fieldname.type], '#'),
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
      local params = (
        if 'params' in field
        then self.fieldName(field) + '(' + a.objectToString(field.params) + ')'
        else self.fieldName(field) + '()'
      );
      local comments =
        local lines = self.getCommentBeforeLine(field.location.line);
        local toStrip = '`%s`\n' % self.fieldName(field);
        if std.startsWith(lines, toStrip)
        then lines[std.length(toStrip):]
        else lines;
      self.renderFunction(
        name,
        params,
        comments,
        depth,
      )
      + (
        if field.expr.type == 'object'
        then self.renderObject(field.expr, [name + '()'], depth, true)
        else []
      )
    ,

    renderAnonymousFunction(field, parents, depth):
      local name = std.join('.', parents + [self.fieldName(field)]);
      self.renderFunction(
        name,
        (
          if 'params' in field.expr
          then self.fieldName(field) + '(' + a.objectToString(field.expr.params) + ')'
          else self.fieldName(field) + '()'
        ),
        self.getCommentBeforeLine(field.location.line),
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
            if std.startsWith(str, '@')
            then '* ' + str
            else str,
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
          )
        ),
      ),
  },
}
