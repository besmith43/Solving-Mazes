class DepthFirstSearch
  def initialize(graph, source_node)
    @graph = graph
    @source_node = source_node
    @visited = []
    @edge_to = {}

	if $verbose
		puts ""
		if $jruby
			@progress = ProgressBar.create(:titel => "Solving the Maze", :total => @graph.nodes.count)
		else
			@progress = ProgressBar.create(:title => "Solving the Maze", :total => @graph.nodes.count, format: 'Progress %c %C |%b>%i| %a %e')
		end
	end

    dfs(source_node)
  end

  def path_to(node)
    return unless has_path_to?(node)
    path = []
    current_node = node

    while(current_node != @source_node) do
      path.unshift(current_node)
      current_node = @edge_to[current_node]
    end

    path.unshift(@source_node)
  end

  private
  def dfs(node)
    @visited << node
    node.adjacent_edges.each do |adj_edge|
		if $verbose
			if @progress.finished?
				@progress.stop
			else
				@progress.increment
			end
		end

		next if @visited.include?(adj_edge.to)

		dfs(adj_edge.to)
		@edge_to[adj_edge.to] = node
    end
  end

  def has_path_to?(node)
    @visited.include?(node)
  end
end
