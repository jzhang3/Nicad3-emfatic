% consistent renaming - Emfatic functions
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

% Generic consistent renaming

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
	    PC [renameIds]%[renameTypes]
	EndXML 
end rule

% Rule to normalize using consistent renaming of types
% to normal form (x1, x2, x3, ...)

function renameTypes
    replace [potential_clone]
        PC [potential_clone]

    % Make a list of all of the unique identifiers 
    construct TypeList [repeat type]
        _ [^ PC] [removeDuplicateTypes]

    % Make normalized new names of the form xN for each of them
    construct GenTypes [repeat type]
        TypeList [genTypes 0]

    % Consistently replace each instance of each one by its normalized form
    by
        PC [$ each TypeList GenTypes]
end function

% Utility rule - remove duplicate Types from a list

function removeDuplicateTypes
    replace [repeat type]
        Type [type] 
	    Rest [repeat type]
    by
	    Type
        Rest [removeTypes Type]
	     [removeDuplicateTypes]
end function

rule removeTypes Type [type]
    replace [repeat type]
        Type
	    More [repeat type]
    by
        More
end rule

% Utility rule - make a normalized id of the form xN for each unique id in a list

function genTypes NM1 [number]
    % For each type in the list
    replace [repeat type]
        _ [type] 
        Rest [repeat type] 

    % Generate the next tN id
    construct N [number]
        NM1 [+ 1]
    construct GenId [id]
        _ [+ 't] [+ N]

    % Replace the id with the generated one
    % and recursively do the next one
    by
        GenId 
        Rest [genTypes N]
end function

%-----------------------------------------------------------
% Rule to normalize using consistent renaming of identifiers
% to normal form (x1, x2, x3, ...)

function renameIds
    replace [potential_clone]
        PC [potential_clone]

    % Make a list of all of the unique identifiers 
    construct Ids [repeat id]
        _ [^ PC] [removeDuplicateIds]

    % Make normalized new names of the form xN for each of them
    construct GenIds [repeat id]
        Ids [genIds 0]

    % Consistently replace each instance of each one by its normalized form
    by
        PC [$ each Ids GenIds]
end function

% Utility rule - remove duplicate ids from a list

function removeDuplicateIds
    replace [repeat id]
        Id [id] 
	Rest [repeat id]
    by
	Id
        Rest [removeIds Id]
	     [removeDuplicateIds]
end function

rule removeIds Id [id]
    replace [repeat id]
        Id
	More [repeat id]
    by
        More
end rule

% Utility rule - make a normalized id of the form xN for each unique id in a list

function genIds NM1 [number]
    % For each id in the list
    replace [repeat id]
        _ [id] 
        Rest [repeat id] 

    % Generate the next xN id
    construct N [number]
        NM1 [+ 1]
    construct GenId [id]
        _ [+ 'x] [+ N]

    % Replace the id with the generated one
    % and recursively do the next one
    by
        GenId 
        Rest [genIds N]
end function

