params = ARGV

$help = params.include?("--help")
$version = params.include?("--version")

if params.include?("--verbose") or params.include?("-v")
	$verbose = true
else
	$verbose = false
end

if params.include?("--method") or params.include?("-m")
	if params.include?("--method")
		index = params.index("--method")
	elsif params.include?("-m")
		index = params.index("-m")
	else
		exit 1
	end

	$method = params[index + 1]
else
	$method = "dijkstra"
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
