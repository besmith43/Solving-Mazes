class BreadthFirstSearch
  def initialize(graph, source_node)
    @graph = graph
    @node = source_node
    @visited = []
    @edge_to = {}

	if $verbose
		@progress = ProgressBar.create(:title => "Solving the Maze", :total => @graph.edges.count, format: 'Progress %c %C |%b>%i| %a %e')
	end

    bfs(source_node)
  end

  def shortest_path_to(node)
    return unless has_path_to?(node)
    path = []

    while(node != @node) do
      path.unshift(node) 
      node = @edge_to[node]
    end

    path.unshift(@node)
  end

  private
  def bfs(node)
    queue = []
    queue << node
    @visited << node

    while queue.any?
	  if $verbose
		  if @progress.finished?
			  @progress.stop
		  else
			  @progress.increment
		  end
	  end

      current_node = queue.shift 
      current_node.adjacent_edges.each do |adjacent_edge|
		  next if @visited.include?(adjacent_edge.to)
		  queue << adjacent_edge.to
		  @visited << adjacent_edge.to
		  @edge_to[adjacent_edge.to] = current_node
      end
    end
  end

  def has_path_to?(node)
    @visited.include?(node)
  end
end
