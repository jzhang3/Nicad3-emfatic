% Example using TXL 10.5a source coordinate extensions to extract
% a table of all method definitions with source coordinates

% Jia Zhang, June 2015

% Requires TXL 10.5a or later

% Using Java 5 grammar
include "emf.grm"

% Main function - extract and mark up function definitions from parsed input program
function main
    match [program]
	P [program]
end function
