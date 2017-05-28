params = ARGV

$help = params.include?("--help")
$version = params.include?("--version")

if params.include?("--verbose") or params.include?("-v")
	$verbose = true
else
	$verbose = false
end

if $help
	puts "Help was passed"
	exit 
end

if $version
	puts ""
	puts "Maze Solver"
	puts "Version: 0.5"
	puts ""
	exit
end

require_relative 'maze'
maze
