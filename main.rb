params = ARGV

$help = params.include?("--help")
$version = params.include?("--version")

if RUBY_PLATFORM == "java"
	$jruby = true
else
	$jruby = false
end

if params.include?("--verbose") or params.include?("-v")
	$verbose = true
else
	$verbose = false
end

if params.include?("--benchmark") or params.include?("-b")
	$benchmark = true
else
	$benchmark = false
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
	puts ""
	puts "USAGE: ruby main.rb [options]"
	puts "	--benchmark			times the process of solving the selected maze"
	puts "	--method			specifies which pathfinding algorithm to use - defaults to Dijkstra"
	puts "						breadth_first_search"
	puts "						depth_first_search"
	puts "						dijkstra"
	puts "	--verbose			displays progress bars at various points in the program"
	puts "	--version			displays the version number"
	puts "	--help				shows this message"
	puts ""
	exit 
end

if $version
	puts ""
	puts "Maze Solver"
	puts "Version: 0.7"
	puts ""
	exit
end

require_relative 'maze'
maze
