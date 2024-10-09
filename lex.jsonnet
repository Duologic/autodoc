local lexer = import './vendor/github.com/Duologic/jsonnet-parser/lexer.libsonnet';
local parser = import './vendor/github.com/Duologic/jsonnet-parser/parser.libsonnet';
local a = import './vendor/github.com/crdsonnet/astsonnet/schema.libsonnet';
local file = importstr './test.libsonnet';

local parsed = parser.new(file).parse();

{

  local commentBeforeLine(f, lineNr) =
    local lines = std.split(f, '\n');
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

    std.map(
      function(str)
        std.lstripChars(str, '#/ '),
      std.reverse(comments)
    ),

  local normalizeType(field) =
    if field.type == 'field_function'
       || field.expr.type == 'anonymous_function'
    then 'function'
    else if field.expr.type == 'literal' && std.member(['true', 'false'], field.expr.literal)
    then 'boolean'
    else field.expr.type,

  local generateFieldHeader(field, parents, depth) =
    local type = normalizeType(field);

    local signature =
      field.fieldname[field.fieldname.type]
      + (
        if 'params' in field
        then '(' + a.objectToString(field.params) + ')'
        else if 'params' in field.expr
        then '(' + a.objectToString(field.expr.params) + ')'
        else ''
      );

    [
      std.join('', ['#' for i in std.range(1, depth)])
      + (' (%s) ' % type)
      + std.join(
        '.',
        parents
        + [signature]
      ),
    ],

  local types = {
    field: dField,
    field_function: dFieldFunction,

    object: dObj,
    anonymous_function: dAnonymousFunction,
  },

  local dField(field, parents, depth) =
    local type = normalizeType(field);
    local fn = std.get(types, field.expr.type);
    if type != 'literal'  // don't document self and $ refs
    then std.get(types, field.expr.type, generateFieldHeader)(field, parents, depth)
    else [],

  local dParams(params) =
    [
      '* '
      + std.join(
        '\n* ',
        [
          param.id.id
          + (
            if 'expr' in param
            then '\n  * default: ' + a.objectToString(param.expr)
            else ''
          )
          for param in params
        ]
      ),
    ],

  local dFieldFunction(field, parents, depth) =
    generateFieldHeader(field, parents, depth)
    + dParams(std.get(field, 'params', { params: [] }).params)
    + commentBeforeLine(file, field.line),

  local dAnonymousFunction(field, parents, depth) =
    generateFieldHeader(field, parents, depth)
    + dParams(std.get(field.expr, 'params', { params: [] }).params)
    + commentBeforeLine(file, field.line),

  local dObj(field, parents, depth) =
    generateFieldHeader(field, parents, depth)
    + ['']
    + start(field.expr, parents + [field.fieldname[field.fieldname.type]], depth),

  local start(object, parents=[], depth=0) =
    // sort some field before others
    local sortF(field) =
      local preference = [
        'function',
        'object',
        'array',
      ];
      local findPreference =
        std.find(normalizeType(field), preference);
      if std.length(findPreference) > 0
      then findPreference[0]
      else std.length(preference);

    local documentableFields =
      std.sort(
        std.filter(
          function(member)
            std.member(['id', 'string'], member.fieldname.type),
          std.get(object, 'members', []),
        ),
        sortF
      );

    local functions = std.filter(function(field) normalizeType(field) == 'function', documentableFields);
    local fields = std.filter(function(field) !std.member(['object', 'function'], normalizeType(field)), documentableFields);

    std.foldl(
      function(acc, field)
        local lines = types[field.type](field, parents, depth + 1);
        acc
        + (if acc != [] && std.length(lines) > 0
           then ['']
           else [])
        + lines,
      functions,
      []
    )
    + std.foldl(
      function(acc, field)
        local lines = types[field.type](field, parents, depth + 1);
        acc
        + (if acc != [] && std.length(lines) > 0
           then ['']
           else [])
        + lines,
      fields,
      []
    ),
  out:
    start(parsed),
}.out
