% Blind renaming - Emfatic functions
% Jia Zhang, June 2015

% Using Emfatic grammar
include "emf.grm"

define class_definition
    [class_header]
    '{                                        [NL][IN] 
	[repeat classMemberDecl]     [EX]
    '}
end define

define class_header
	[opt abstractModifier] [classKind] [id] [opt typeParamsInfo] [opt extendsClause][opt instance] 
end define

redefine elements
	...|
	[number] [type] [id] [opt parameters] ';
end redefine


define type
	[resultType]
end define

define parameters
	'( [params]')
end define

define potential_clone
    [class_definition]
end define

% Generic blind renaming


define xml_source_coordinate
    '< [SPOFF] 'source [SP] 'file=[stringlit] [SP] 'startline=[stringlit] [SP] 'endline=[stringlit] '> [SPON] [NL]
end define

define end_xml_source_coordinate
    [NL] '< [SPOFF] '/ 'source '> [SPON] [NL]
end define

define source_unit  
    [xml_source_coordinate]
        [potential_clone]
    [end_xml_source_coordinate]
end define

redefine program
    [repeat source_unit]
end redefine

% Main program

rule main
    skipping [source_unit]
    replace $ [source_unit]
	BeginXML [xml_source_coordinate]
	    PC [potential_clone]
	EndXML [end_xml_source_coordinate]
    by
	BeginXML 
	    PC [renameType][renameIds]
	EndXML 
end rule

rule renameType
    replace $ [resultType]
        _ [resultType]
    by
	'x
end rule

rule renameIds
    replace $ [id]
        _ [id]
    by
	'x
end rule
