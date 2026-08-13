
# CSR Graph 结构

Builder b(cli);
typedef BuilderBase<NodeID, NodeID, WeightT> Builder;
typedef EdgePair<NodeID_, DestID_> Edge;
typedef pvector<Edge> EdgeList;


class BuilderBase { };

 Builder b(cli);
 Graph g = b.MakeGraph();
       scale默认-1， 必须指定；  degree默认16. 
       平均每个点的邻接表长度16， 每个nodeid 是int32,, 邻接表平均是 64B；
       它使用压缩的CSR存储图。


 MakeGraph():

    Generator<NodeID_, DestID_> gen(cli_.scale(), cli_.degree()); // 确定 degree,  scale ,
    el = gen.GenerateEL(cli_.uniform()); //  一般是 K图， 返回 边的列表。
        其中  return  el = MakeRMatEL(); //  el是服从分布规律的边的列表
    g = MakeGraphFromEL(el);  // 根据 el 构造 图g
        MakeCSR(el,  transpose,  index, neighs);
           CountDegrees(el);  // 计算每个点的度
           ParallelPrefixSum(degrees);  // 计算每个点的邻接表的偏移量
           构造CSR存放顶点的邻接表。并更新每个邻接表的偏移量；
        return  CSRGraph(num_nodes_, index, neighs);  // 使用index和neighs构造CSRGraph 
           直接对CSRGraph的成员赋值；
    CCBound = [&cli](const Graph& gr){ return Afforest(gr, cli.logging_en()); };       
    //一个 C++ Lambda，用来把 Afforest 从 2 个参数 → 包装成 1 个参数，方便传给 BenchmarkKernel。
    最后启动kernel

# 构造真实的图

make bench-graphs

    
