file: podTemplate  ;

podTemplate:
  ('Global' 'Variables' COLON globalVariables)?
  'podTemplate' '('
    'inheritFrom' ':' QSTRING','// TODO: allow simple quotes, order independant params
    'containers' ':' '['
      (containerTemplate (',' containerTemplate)* ','?)? ']'
  ')' '{'
    'node' '(' 'POD_LABEL' ')' '{'
      stage*
    '}'
  '}';

globalVariables: line;
containerTemplate: 'containerTemplate' '(' (containerTemplateParameter (',' containerTemplateParameter)* ','?)? ')';
containerTemplateParameter
  : 'name' ':' QSTRING
  | 'image' ':' QSTRING
  | 'alwaysPullImage' ':' BOOLEAN
  | 'ttyEnabled' ':' BOOLEAN
  | 'command' ':' QSTRING
  ;

stage:  'stage' '(' stageName ')' '{' stageBody '}';
stageName: QSTRING;
stageBody
  : codeCheckout
  | buildAndTestJava
  | buildAndTestJavaScript
  | buildAndTestDotNet
  | buildAndTestPython
  | deployTerraform
  | dockerBuild
  | dockerPush
  | deployKubernetes
  | customStage
;