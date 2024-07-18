"use strict";

var output = output || {};
output.consts = output.consts || {};

output.consts.dicebot = 'GranCrest';

output.consts.initiative = { label:'行動値', name: 'sttInitTotal' };

output.consts.GC_PARAMS = [
  { name: 'レベル', value: 'level' },
  { name: '筋力', value: 'sttStrCheckTotal', force:'force1Str' },
  { name: '反射', value: 'sttRefCheckTotal', force:'force1Ref' },
  { name: '感覚', value: 'sttPerCheckTotal', force:'force1Per' },
  { name: '知力', value: 'sttIntCheckTotal', force:'force1Int' },
  { name: '精神', value: 'sttMndCheckTotal', force:'force1Mnd' },
  { name: '共感', value: 'sttEmpCheckTotal', force:'force1Emp' },
];