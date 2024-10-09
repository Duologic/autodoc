local parser = import './parser.libsonnet';
local file = importstr './example.libsonnet';
parser.new(file).parse()
