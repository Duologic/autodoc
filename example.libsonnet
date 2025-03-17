local autodoc = import './main.libsonnet';

{
  'README.md':
    autodoc.new(
      'Autodoc',
      (importstr './main.libsonnet')
    ).render(0),
}
