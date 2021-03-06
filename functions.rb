def read_image(png_file)
	image = ChunkyPNG::Image.from_file(png_file)

	rows = image.dimension.width
	cols = image.dimension.height

	if $verbose
		puts ""
		puts "Reading Image from File"
		if $jruby
			prog_bar = ProgressBar.create(:title => "Reading Image from File", :total => rows*cols)
		else
			prog_bar = ProgressBar.create(:title => "Reading Image from File", :total => rows*cols, format: 'Progress %c %C |%b>%i| %a %e')
		end
	end

	maze = Array.new(cols) { Array.new(rows) }

	m = Mutex.new
	threads = []

	(0..rows-1).each do |x|
		threads << Thread.new {
			(0..cols-1).each do |y|
				if $verbose
					prog_bar.increment
				end

				r = ChunkyPNG::Color.r(image[x,y])
				g = ChunkyPNG::Color.g(image[x,y])
				b = ChunkyPNG::Color.b(image[x,y])

				if r == 255 and g == 255 and b == 255
					m.synchronize do
						maze[y][x] = 0
					end
				elsif r == 0 and g == 0 and b == 0
					m.synchronize do
						maze[y][x] = 1
					end
				else
					exit 1
				end
			end
		}
	end

	threads.each do |t| t.join end

	return maze, rows, cols
end

def write_image(maze, rows, cols)
	if $verbose
		puts ""
		puts "Writing Image to File"
		if $jruby
			prog_bar = ProgressBar.create(:title => "Writing Image to File", :total => rows*cols)
		else
			prog_bar = ProgressBar.create(:title => "Writing Image to File", :total => rows*cols, format: 'Progress %c %C |%b>%i| %a %e')
		end
	end

	image = ChunkyPNG::Image.new rows, cols

	m = Mutex.new
	threads = []

	(0..cols-1).each do |x|
		threads << Thread.new {
		(0..rows-1).each do |y|
			if $verbose
				prog_bar.increment
			end

			if maze[y][x] == 0
				m.synchronize do
					image[x,y] = ChunkyPNG::Color(255, 255, 255)
				end
			elsif maze[y][x] == 1
				m.synchronize do
					image[x,y] = ChunkyPNG::Color(0, 0, 0)
				end
			elsif maze[y][x] == 2
				m.synchronize do
					image[x,y] = ChunkyPNG::Color(255, 0, 0)
				end
			end
		end
		}
	end

	threads.each do |t| t.join end

	cli = HighLine.new

	filename = cli.ask("Solved Maze File Name: ") { |q| q.default = "test.png" }
	image.save filename

end

def get_nodes(maze, rows, cols)
	if $verbose
		puts ""
		puts "Collecting Nodes"
		if $jruby
			prog_bar = ProgressBar.create(:title => "Collecting Nodes", :total => rows*cols)
		else
			prog_bar = ProgressBar.create(:title => "Collecting Nodes", :total => rows*cols, format: 'Progress %c %C |%b>%i| %a %e')
		end
	end

	node_maze = Array.new(cols) { Array.new(rows) {0} }

	num_nodes = 0
	num_edges = 0
	connected_to_start = false
	num_possible_paths = 0
	entrance = 0
	finish = 0
	graph = Graph.new

	m = Mutex.new
	threads = []

	(0..cols-1).each do |x|
		if $verbose
			prog_bar.increment
		end
		
		if maze[0][x] == 0
			entrance = x
			num_nodes += 1
			@node1 = Node.new("node1", 0, x)
			graph.add_node(@node1)
			node_maze[0][x] = num_nodes
		end
	end

	(0..cols-1).each do |x|
		threads << Thread.new {
			(1..rows-2).each do |y|
				if $verbose
					prog_bar.increment
				end
			
				if maze[y][x] == 0
					if maze[y][x+1] == 0 and maze[y][x-1] == 0 and maze[y+1][x] == 1 and maze[y-1][x] == 1
						# corridor
					elsif maze[y][x+1] == 1 and maze[y][x-1] == 1 and maze[y+1][x] == 0 and maze[y-1][x] == 0
						# corridor
					else
						m.synchronize do
							num_nodes += 1
							instance_variable_set("@node#{num_nodes}", Node.new("node#{num_nodes}", y, x))
							graph.add_node(eval("@node#{num_nodes}"))
							node_maze[y][x] = num_nodes
						end
					end
				end
			end
		}
	end

	threads.each do |t| t.join end

	threads = []

	(0..cols-1).each do |x|
		threads << Thread.new {
			(1..rows-2).each do |y|
				if node_maze[y][x] != 0
					m.synchronize do
						current_node = node_maze[y][x]
						search_x = x-1
						search_y = y-1
						distance = 1
						found_node = 0
						connected_to_start = false

						until maze[y][search_x] == 1
							if node_maze[y][search_x] == 0
								search_x -= 1
								distance += 1
							else
								found_node = node_maze[y][search_x]
								graph.add_edge(eval("@node#{current_node}"), eval("@node#{found_node}"), distance)
								graph.add_edge(eval("@node#{found_node}"), eval("@node#{current_node}"), distance)
								distance = 1
								num_edges += 1
								break
							end
						end

						until maze[search_y][x] == 1 or connected_to_start == true
							if node_maze[search_y][x] == 0
								search_y -= 1
								distance += 1
							else
								found_node = node_maze[search_y][x]
								graph.add_edge(eval("@node#{current_node}"), eval("@node#{found_node}"), distance)
								graph.add_edge(eval("@node#{found_node}"), eval("@node#{current_node}"), distance)
								if search_y == 0
									connected_to_start = true
								end
								distance = 1
								num_edges += 1
								break
							end
						end
					end
				end
			end
		}
	end

	threads.each do |t| t.join end

	(0..cols-1).each do |x|
		if $verbose
			prog_bar.increment
		end

		if maze[rows-1][x] == 0
			finish = x
			num_nodes += 1
			instance_variable_set("@node#{num_nodes}", Node.new("node#{num_nodes}", rows-1, finish))
			graph.add_node(eval("@node#{num_nodes}"))
			node_maze[rows-1][x] = num_nodes

			search_y = rows-2
			distance = 1
			found_node = 0

			until maze[search_y][x] == 1
				if node_maze[search_y][x] == 0
					search_y -= 1
					distance += 1
				else
					found_node = node_maze[search_y][x]
					graph.add_edge(eval("@node#{num_nodes}"), eval("@node#{found_node}"), distance)
					graph.add_edge(eval("@node#{found_node}"), eval("@node#{num_nodes}"), distance)
					num_edges += 1
					break
				end
			end
		end
	end

	return graph, num_nodes
end

def solve(graph, num_nodes, maze, rows, cols)
	if $verbose
		puts ""
		puts "Solving the Maze"
	end

	case $method
	when "dijkstra"
		if $benchmark
			require 'benchmark'
			t1 = Benchmark.realtime do
				require_relative 'dijkstra'
				@shortest_path = Dijkstra.new(graph, @node1).shortest_path_to(eval("@node#{num_nodes}"))
			end

			puts "\nDijkstra Time: #{t1}"
		else
			require_relative 'dijkstra'
			@shortest_path = Dijkstra.new(graph, @node1).shortest_path_to(eval("@node#{num_nodes}"))
		end
		
	when "breadth_first_search"
		if $benchmark
			require 'benchmark'
			t1 = Benchmark.realtime do
				require_relative 'breadth_first_search'
				@shortest_path = BreadthFirstSearch.new(graph, @node1).shortest_path_to(eval("@node#{num_nodes}"))
			end

			puts "\nBreadth First Search Time: #{t1}"
		else
			require_relative 'breadth_first_search'
			@shortest_path = BreadthFirstSearch.new(graph, @node1).shortest_path_to(eval("@node#{num_nodes}"))
		end
	when "depth_first_search"
		if $benchmark
			require 'benchmark'
			t1 = Benchmark.realtime do
				require_relative 'depth_first_search'
				@shortest_path = DepthFirstSearch.new(graph, @node1).path_to(eval("@node#{num_nodes}"))
			end

			puts "\nDepth First Search Time: #{t1}"
		else
			require_relative 'depth_first_search'
			@shortest_path = DepthFirstSearch.new(graph, @node1).path_to(eval("@node#{num_nodes}"))
		end
	else
		puts ""
		puts "Invalid Method"
		exit 1
	end

	@shortest_path
end

def graph_solution(shortest_path, num_nodes, maze, rows, cols)
	if $verbose
		puts ""
		puts "Graphing the Solution to the Maze"
	end

	x = -1
	y = -1

	shortest_path.each do |node|
		temp_x = node.get_x
		temp_y = node.get_y

		maze[temp_y][temp_x] = 2

		if x > -1 and y > -1
			if x == temp_x and y > temp_y
				(temp_y..y).each do |new_y|
					maze[new_y][x] = 2
				end
			elsif x == temp_x and y < temp_y
				(y..temp_y).each do |new_y|
					maze[new_y][x] = 2
				end
			elsif x > temp_x and y == temp_y
				(temp_x..x).each do |new_x|
					maze[y][new_x] = 2
				end
			elsif x < temp_x and y == temp_y
				(x..temp_x).each do |new_x|
					maze[y][new_x] = 2
				end
			end
		end

		x = temp_x
		y = temp_y
	end

	maze
end

def select_maze
	cli = HighLine.new
	png_files = []

	png_files = Dir.glob('examples/*.png')

	puts ""

	cli.choose do |menu|
		menu.prompt = "\nPlease choose which Maze you would like to solve"
		menu.choices(*png_files) do |chosen|
			puts "Maze Chosen: #{chosen}"
			return chosen
		end
	end
end

