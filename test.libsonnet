local a = '';

// Something about this object
{
  key1: 't',
  [if true then 'a']: 'b',
  newSub: function(b=5) {},
  '112': 'bb',
  bool: true,
  // This is a number
  number: 44,
  nll: null,
  // Creates a new object
  //
  // PARAMETERS:
  //  - **name** (`string`) - name of the object
  new: function(name='mylovelyname') {},

  // Another bit about another  object
  subObject: {
    // this'll return an empty string
    myObjFunc(): '',
    aaaaaaa: 34,
  },
  arr: [],
  withArg(a): {},

  // this is a function without args that does nothing but return an empty object
  withoutArgs: function() {},

  s: self,
}
