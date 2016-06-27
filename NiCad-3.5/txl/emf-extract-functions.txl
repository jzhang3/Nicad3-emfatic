% Example using TXL 10.5a source coordinate extensions to extract
% a table of all class/interface/enum definitions with source coordinates

% v1.0. Jia Zhang, June 2015


% Using Emfatic grammar
include "emf.grm"

% Ignore BOM headers from Windows
%include "bom.grm"

% Redefinitions to collect source coordinates for function definitions as parsed input,
% and to allow for XML markup of function definitions as output


redefine classDecl
	[repeat annotation]			% Remove @Override annotations from clone comparison
	[class_definition]
    |  
    	[class_header]
%    	[opt annotation_default] ';               [NL][NL]
end redefine

define class_header
	[opt abstractModifier] [classKind] [id] [opt typeParamsInfo] [opt extendsClause][opt instance] 
end define

define class_definition
	% Input form 
	[srcfilename] [srclinenumber] 		% Keep track of starting file and line number
	[class_header]
	'{                                        [NL][IN] 
	    [repeat classMemberDecl]     [EX]
	    [srcfilename] [srclinenumber] 	% Keep track of ending file and line number
	'}
    |
	% Output form 
	[not token]				% disallow output form in input parse
	[opt xml_source_coordinate]
	[class_header]
	'{                                        [NL][IN] 
	    [repeat classMemberDecl]     [EX]
	'}
	[opt end_xml_source_coordinate]
end define

define xml_source_coordinate
    '< [SPOFF] 'source [SP] 'file=[stringlit] [SP] 'startline=[stringlit] [SP] 'endline=[stringlit] '> [SPON] [NL]
end define

define end_xml_source_coordinate
    [NL] '< [SPOFF] '/ 'source '> [SPON] [NL]
end define

% in order to sort element, redefine elements
redefine elements
	...|
	[number] [type] [id] [opt parameters] ';
%	| [number] [stringlit]';
end redefine


define type
	[resultType]
end define

define parameters
	'( [params]')
end define

redefine classMemberDecl
	...|
	[repeat elements]
end redefine

% union input form and output form
redefine program
	...
    | 	[repeat class_definition]
end redefine


% Main function - extract and mark up function definitions from parsed input program
function main
    replace [program]
	P [program]
    construct Functions [repeat class_definition]
    	_ [^ P] 			% Extract all functions from program
	  [convertFunctionDefinitions] 	% Mark up with XML
    by 
    	Functions 
end function

rule convertFunctionDefinitions
    % Find each function definition and match its input source coordinates
    replace [class_definition]
	FileName [srcfilename] LineNumber [srclinenumber]
	FunctionHeader [class_header]
	'{
	    FunctionBody [repeat classMemberDecl]
	    EndFileName [srcfilename] EndLineNumber [srclinenumber]
	'}

    % Convert file name and line numbers to strings for XML
    construct FileNameString [stringlit]
	_ [quote FileName] 
    construct LineNumberString [stringlit]
	_ [quote LineNumber] 
    construct EndLineNumberString [stringlit]
	_ [quote EndLineNumber] 

    % Output is XML form with attributes indicating input source coordinates
    construct XmlHeader [xml_source_coordinate]
	<source file=FileNameString startline=LineNumberString endline=EndLineNumberString>
    by
	XmlHeader
	FunctionHeader [removeClassHearderInfo]
	'{
	    FunctionBody [removeAnnoAndModifiers][removeTypeArgs]
	                 [removeOperationElements][removeParam]
	                 [removeOpposite][removeDefaultValue]
	                 [removeMultiplicity][numberRef][numberVal]
	                 [removeIDseperator]
	                 [sortByKind][sortByType][sortByID]	                 
	'}
	</source>
end rule

%-----------------------  filtering --------------------------

% remove the part that after ID in class header
rule removeClassHearderInfo
	replace $ [class_header]
		Modifiers [opt abstractModifier] 
		Kind [classKind] 
		ID [id] 
		Info [opt typeParamsInfo]
		Extend [opt extendsClause]
		Instance [opt instance] 		
	by
		Modifiers 
		Kind  
		ID 
end rule


% remove annotations and modifiers of elements
rule removeAnnoAndModifiers
	replace $ [classMemberDecl]
		Annotations [annotations] 
		Modifiers [modifiers] 
		Elements [elements]
	by
		Elements
end rule

% remove generic super type
rule removeTypeArgs
	replace $ [boundExceptWildcard]
		QualifiedID [qualifiedID]
		TypeArgs [opt oneOrMoreTypeArgs]
	by
		QualifiedID
end rule


% remove annotations and modifiers of parameters
rule removeParam
	replace $ [param]
		Annotations1 [annotations]
		Modifiers [modifiers]
		Type [typeWithMulti]
		ID [id]
		Annotations2 [annotations]
	by
		Type ID
end rule



rule removeOpposite
	replace $ [reference]
		ReferenceKind[referenceKind] 
		Type [typeWithMulti]
		Opposite [opt opposite] 
		ID [id] 
		';
	by
		ReferenceKind Type ID ';
end rule

%
rule removeMultiplicity       
	replace $ [typeWithMulti]
		ID [boundExceptWildcard]
		Bound [opt multiplicity]
	by
		ID
end rule

% for rename, simplify the type
rule removeIDseperator
	replace $ [qualifiedID]
		ID [id]
		ID2 [repeat catID]
	by
		ID
end rule

%------------------------- sorting -----------------------------------
% 
rule removeDefaultValue
	replace $ [elements]
	 'attr 
	 Type [typeWithMulti]
	 ID [id] 
	 DefaultValue [opt defaultValue] 
	 '; 
	construct NewElements [elements]
	 	1 Type ID '; 	
	by
	 	NewElements		
end rule

% remove throw
rule removeOperationElements
	replace $ [elements]
		'op
		TypeParams [opt typeParamsInfo]
		Type [resultType]
		ID [id]
		'(  Params [params] ')
		Throw [opt throws]
		';
	construct NewElements [elements]
	    2 Type ID '( Params') ';
	by
		NewElements
end rule

redefine referenceKind
	...|
	[number]
end redefine

rule numberRef
	replace $ [referenceKind]
		'ref
	construct Number [referenceKind]	
	    3
	by
		Number
end rule

rule numberVal
	replace $ [referenceKind]
		'val
	construct Number [referenceKind]
	    4
	by
		Number
end rule


rule sortByKind
	replace [repeat classMemberDecl]
		E1 [classMemberDecl]
		E2 [classMemberDecl]
		Rest [repeat classMemberDecl]
	deconstruct E1
	   Annotation1 [annotations]
	   Modifiers1 [modifiers]
	   E11 [elements]
	 deconstruct * [number] E11  
	   Kind1 [number] 
	deconstruct E2
	   Annotation2 [annotations]
	   Modifiers2 [modifiers]
	   E22 [elements]
	deconstruct * [number] E22	
	   Kind2 [number] 
	where
	    Kind1 [> Kind2]	
	by
		E2 E1 Rest
end rule

rule sortByType
	replace [repeat classMemberDecl]
		E1 [classMemberDecl]
		E2 [classMemberDecl]
		Rest [repeat classMemberDecl]
	deconstruct E1
	   Annotation1 [annotations]
	   Modifiers1 [modifiers]
	   E11 [elements]
	 deconstruct * [number] E11  
	   Kind1 [number] 
	 deconstruct * [id] E11  
	   ID1 [id]
	deconstruct E2
	   Annotation2 [annotations]
	   Modifiers2 [modifiers]
	   E22 [elements]
	deconstruct * [number] E22	
	   Kind2 [number] 
	deconstruct * [id] E22	
	   ID2 [id] 
	where
	    Kind1 [= Kind2]	
	where
	   ID1 [> ID2]
	by
		E2 E1 Rest
end rule

rule sortByID
	replace [repeat elements]
		E1 [elements]
		E2 [elements]
		Rest [repeat elements]
    deconstruct E1
    Kind1 [number]
    Type1 [type]
    ID1 [id]
    Params1 [opt parameters]
    ';
    deconstruct E2
    Kind2 [number]
    Type2 [type]
    ID2 [id]
    Params [opt parameters]
    ';
    deconstruct * [id] Type1
     T1 [id]
    deconstruct * [id] Type2
     T2 [id]
    where
    Kind1 [= Kind2]
    where
    T1 [= T2] 
    where
    ID1 [> ID2]
	by
		E2 E1 Rest
end rule



