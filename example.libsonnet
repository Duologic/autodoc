local n = import './main.libsonnet';

local file = importstr './main.libsonnet';

'# autodoc\n\n'
+ n(file).render(1)
