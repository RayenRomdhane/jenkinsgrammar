grammar jenkins;

LP:  '(';
RP:  ')';
LCB: '{';
RCB: '}';
LSB: '[';
RSB: ']';

COMMA:      ',';
SEMICOLON:  ';';
COLON:      ':';

QUOTE: ["'];
TRIPLE_QUOTES: '"""' | '\'\'\'';

OTHER_SPECIAL_CHARS
  : '-'
  | '!'
  | '$'
  | '&'
  | '*'
  | '+'
  | '.'
  | '/'
  | '<'
  | '='
  | '>'
  | '_'
  | '|'
  | '\\'
  | '#'
  ;

LINE_COMMENT:      '//' ~[\r\n]* -> skip;
HASH_COMMENT:      '#' ~ [\r\n]* -> skip;
MULTILINE_COMMENT: '/*' .*? '*/' -> skip;
WHITESPACE:        [ \t\r\n]+    -> skip;

NUMBER: '0' | [1-9] [0-9]*;

BOOLEAN: 'true' | 'false';

WORD: LetterOrDigit+;

fragment LetterOrDigit: Letter | [0-9];
fragment Letter
    : [a-zA-Z$_.] // these are the "java letters" below 0x7F
    | ~[\u0000-\u007F\uD800-\uDBFF] // covers all characters above 0x7F which are not a surrogate
    | [\uD800-\uDBFF] [\uDC00-\uDFFF] // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
    ;

/**
 * STRING Lexer Rule comes from the JSON grammar
 * https://github.com/antlr/grammars-v4/blob/master/json/JSON.g4
 */
QSTRING
   : QUOTE (ESC | SAFECODEPOINT)* QUOTE
   ;

fragment ESC
   : '\\' (["\\/bfnrt] | UNICODE)
   ;
fragment UNICODE
   : 'u' HEX HEX HEX HEX
   ;
fragment HEX
   : [0-9a-fA-F]
   ;
fragment SAFECODEPOINT
   : ~ ["\\\u0000-\u001F]
   ;

////////////////////////////////////////////////////////////////////////////////

litteral
  : 'podTemplate'
  | 'inheritFrom'
  | 'containers'
  | 'containerTemplate'
  | 'name'
  | 'image'
  | 'alwaysPullImage'
  | 'ttyEnabled'
  | 'command'
  | 'node'
  | 'POD_LABEL'
  | 'stage'
  | 'container'
  | 'withCredentials'
  | 'withEnv'
  | '$class'
  | 'sh'
  | 'cd'
  | 'checkout'
  | 'scm'
  | QUOTE 'GitSCM' QUOTE
  | 'userRemoteConfigs'
  | 'url'
  | 'credentialsId'
  | 'variable'
  | 'branches'
  | 'extensions'
  | QUOTE 'RelativeTargetDirectory' QUOTE
  | 'relativeTargetDir'
  | 'mvn'
  | '-f'
  | '-s'
  | '-t'
  | '-n'
  | 'npm'
  | 'config'
  | 'set'
  | 'registry'
  | 'strict-ssl'
  | 'install'
  | 'run'
  | 'pip'
  | '--upgrade'
  | 'setuptools'
  | 'wheel'
  | '-e'
  | './'
  | 'dotnet'
  | 'restore'
  | '--configfile'
  | 'publish'
  | 'docker'
  | 'build'
  | 'push'
  | 'kubectl'
  | 'apply'
  | 'file'
  | 'deploy'
  | 'k8s'
  | 'ressources'
  | '# deploy k8s ressources'
  | 'echo'
  | QUOTE 'Running Terraform ${GOAL}...' QUOTE
  | 'export'
  | 'ACCOUNT_ID'
  | 'terraform'
  | 'init'
  | '-backend-config'
  | 'if'
  | QUOTE '${GOAL}' QUOTE
  | 'plan'
  | 'destroy'
  | 'fi'
  | '-var-file'
  | 'usernamePassword'
  | 'Global'
  | 'Variables'
  | 'VERSION'
  | 'version'

  ;

word: WORD | litteral;

container: 'container' '(' QSTRING ')';
bashPosArg: QSTRING | word | bashPosArg '=' bashPosArg;
bashOptArg: '-' '-'? word;
bashArg: bashPosArg | bashOptArg;
bashEndl: ';'?;
cdCommand: 'cd' bashPosArg bashEndl;
containerImage: QSTRING ;
dockerString: QUOTE word ':' word QUOTE;
line: (bashPosArg | '-' | '[' | ']' | '(' | ')' | '{' | '}' | '$' | ':' | ',' )* ;

////////////////////////////////////////////////////////////////////////////////

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
  ; // TODO: remaining stages

////////////////////////////////////////////////////////////////////////////////

codeCheckout
  : 'checkout' 'scm'
  | 'checkout' '(' '[' (codeCheckoutParam (',' codeCheckoutParam)* ','?)? ']' ')'
  ;

codeCheckoutGitUrl: QSTRING;
codeCheckoutGitBranchOrTag: QSTRING;
codeCheckoutGitCredentialsId: QSTRING;
codeCheckoutRelativeTargetDir: QSTRING;

codeCheckoutParam
  : '$class' ':' '"GitSCM"'
  | userRemoteConfigs
  | branches
  | extensions
  ;

userRemoteConfigs: 'userRemoteConfigs' ':' '[' '[' (userRemoteConfigParam (',' userRemoteConfigParam)* ','?)? ']' ']';
userRemoteConfigParam
  : 'url' ':' codeCheckoutGitUrl
  | 'credentialsId' ':' codeCheckoutGitCredentialsId
  ;

branches: 'branches' ':' '[' '[' 'name' ':' codeCheckoutGitBranchOrTag ']' ']';

extensions: 'extensions' ':' '[' '[' (extensionParam (',' extensionParam)* ','?)? ']' ']';
extensionParam
  : '$class' ':' '"RelativeTargetDirectory"'
  | 'relativeTargetDir' ':' codeCheckoutRelativeTargetDir
  ;

////////////////////////////////////////////////////////////////////////////////

buildAndTestJava:
  container '{'
    'sh' TRIPLE_QUOTES
      cdCommand?
      mvnCommand bashEndl
    TRIPLE_QUOTES
  '}';

mvnCommand: 'mvn'
  buildAndTestJavaOptions
  '-f' buildAndTestJavaPomFilePath
  '-s' buildAndTestJavaSettingsFilePath
  buildAndTestJavaPhases;

buildAndTestJavaPomFilePath: bashPosArg;
buildAndTestJavaSettingsFilePath: bashPosArg;
buildAndTestJavaPhases: bashPosArg*;
buildAndTestJavaOptions: bashArg*?;

////////////////////////////////////////////////////////////////////////////////

buildAndTestJavaScript:
  container '{'
    'sh' TRIPLE_QUOTES
      cdCommand?
      ('npm' 'config' 'set' 'registry' buildAndTestJavaScriptNpmRegistryUrl bashEndl)?
      ('npm' 'config' 'set' 'strict-ssl' buildAndTestJavaScriptNpmRegistryStrictSsl bashEndl)?
      'npm' 'install' bashEndl
      buildAndTestJavaScriptRunScripts
    TRIPLE_QUOTES
  '}';

npmRunCommand: 'npm' 'run' bashPosArg;

buildAndTestJavaScriptRunScripts: (npmRunCommand bashEndl)*;
buildAndTestJavaScriptNpmRegistryUrl: bashPosArg;
buildAndTestJavaScriptNpmRegistryStrictSsl: BOOLEAN;


////////////////////////////////////////////////////////////////////////////////

buildAndTestDotNet:
  container '{'
    'sh' TRIPLE_QUOTES
      cdCommand?
      'dotnet' 'restore' '--configfile' buildAndTestDotNetNugetConfigFilePath bashEndl
      'dotnet' 'publish' buildAndTestDotNetPublishOptions bashEndl
    TRIPLE_QUOTES
  '}';

buildAndTestDotNetNugetConfigFilePath: bashPosArg;
buildAndTestDotNetPublishOptions: bashArg*;

////////////////////////////////////////////////////////////////////////////////

buildAndTestPython:
  container '{'
    'sh' TRIPLE_QUOTES
      cdCommand?
      'pip' 'install' '--upgrade' 'pip' '&&' 'pip' 'install' 'setuptools' 'wheel'
      'pip' 'install' '-e' './'
      buildAndTestPythonTestCommand bashEndl
    TRIPLE_QUOTES
  '}';

buildAndTestPythonTestCommand: .*?;


////////////////////////////////////////////////////////////////////////////////

dockerBuild:
  container '{'
  dockerBuildUcpUrl?
        'sh' TRIPLE_QUOTES
          'docker' 'build' '-t' dockerBuildImageName (bashOptArg 'VERSION' '=' QSTRING)* '-f' dockerBuildFilePath dockerBuildContextPath
        TRIPLE_QUOTES
  '}'
 line?
;

dockerBuildUcpUrl: line ;
dockerBuildCredentialsId: line? ;
dockerBuildImageName: bashPosArg;
dockerBuildImageTag: bashPosArg;
dockerBuildContextPath: bashPosArg;
dockerBuildFilePath: bashPosArg;


////////////////////////////////////////////////////////////////////////////////


dockerPush:
 container '{'
  ('withCredentials' LP LSB 'file' LP 'credentialsId' COLON dockerPushCredentialsId ',' 'variable' COLON QSTRING RP RSB RP)? '{'?
    dockerPushUcpUrl
        'sh' TRIPLE_QUOTES
          'docker' 'push' dockerPushImageName
        TRIPLE_QUOTES
      '}'
    line?
    
;

dockerPushUcpUrl: line? ;
dockerPushCredentialsId: bashPosArg ;
dockerPushImageName: bashPosArg;


////////////////////////////////////////////////////////////////////////////////


deployKubernetes:
  container '{'
   'withCredentials' LP LSB 'file' LP 'credentialsId' COLON kubeCredentialsId ',' 'variable' COLON QSTRING RP RSB RP '{'
        line
        'sh' TRIPLE_QUOTES
          ('cd' kubeWorkingDir )*
          kubePreCommand
          '# deploy k8s ressources'
          ('kubectl' 'apply' '-n' kubeNamespace '-f' fichier=kubeFile)+

        TRIPLE_QUOTES
  '}'
  '}'

;

kubeNamespace: bashPosArg ;
kubeCredentialsId: bashPosArg ;
kubeFile: bashPosArg;
kubeWorkingDir: bashPosArg;
kubePreCommand: line?;
kubePostCommand: line?;

////////////////////////////////////////////////////////////////////////////////

deployTerraform:
  container '{'
  'withCredentials' '(' '['
    'usernamePassword' '(' 'credentialsId' ':' terraformCredentialsId ',' 'usernameVariable' ':' bashPosArg ',' 'passwordVariable' ':' bashPosArg ')' ','?
    ( 'usernamePassword' '(' 'credentialsId' ':' bucketCredentialsId ',' 'usernameVariable' ':' bashPosArg ',' 'passwordVariable' ':' bashPosArg ')')?
    ']' ')'
    '{'
    'echo' '"Running Terraform ${GOAL}..."'
    'sh' TRIPLE_QUOTES
      'export' 'ACCOUNT_ID' '=' deployTerraformAccountId
      ('cd' terraformWorkingDir )*
      'echo' line
      'terraform' 'init' '-backend-config' '=' deployTerraformBackendFilePath
      'echo' line
      terraformCondition
      'terraform' 'plan' '-var-file' '=' tfvarsFilePath line
      terraformCondition
      'terraform' 'apply' '-var-file' '=' tfvarsFilePath line
      terraformCondition
      'terraform' 'destroy' '-var-file' '=' tfvarsFilePath line
      'fi'
     TRIPLE_QUOTES
     '}'
  '}';


deployTerraformAccountId: bashPosArg;
terraformWorkingDir: bashPosArg;
deployTerraformBackendFilePath: bashPosArg;
terraformCondition:  ('elif'|'if') '[' '[' QSTRING '=' '=' QSTRING ']' ']' bashEndl 'then' ;
tfvarsFilePath: bashPosArg;
terraformCredentialsId: bashPosArg;
bucketCredentialsId: bashPosArg;

////////////////////////////////////////////////////////////////////////////////
customStage: .*?;