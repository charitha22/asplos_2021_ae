__global__ void initContext(GraphChiContext* context, int vertices, int edges) {
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if (tid == 0) {
	context->setNumIterations(0);
	context->setNumVertices(vertices);
	context->setNumEdges(edges);
    }
}

__global__ void initObject(VirtVertex<int, int> **vertex, GraphChiContext* context,
	int* row, int* col, int* inrow, int* incol) {
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if (tid < context->getNumVertices()) {
	int out_start = row[tid];
	int out_end;
	if (tid + 1 < context->getNumVertices()) {
	    out_end = row[tid + 1];
	} else {
	    out_end = context->getNumEdges();
	}
	int in_start = inrow[tid];
	int in_end;
	if (tid + 1 < context->getNumVertices()) {
	    in_end = inrow[tid + 1];
	} else {
	    in_end = context->getNumEdges();
	}
	int indegree = in_end - in_start;
	int outdegree = out_end - out_start;
	vertex[tid] = new ChiVertex<int, int>(tid, indegree, outdegree);
	vertex[tid]->setValue(INT_MAX);
	for (int i = in_start; i < in_end; i++) {
	    vertex[tid]->setInEdge(i - in_start, incol[i], INT_MAX);
	}
	//for (int i = out_start; i < out_end; i++) {
	//    vertex[tid]->setOutEdge(vertex, tid, i - out_start, col[i], 0.0f);
	//}
    }
}

__global__ void initOutEdge(VirtVertex<int, int> **vertex, GraphChiContext* context,
	int* row, int* col) {
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if (tid < context->getNumVertices()) {
	int out_start = row[tid];
	int out_end;
	if (tid + 1 < context->getNumVertices()) {
	    out_end = row[tid + 1];
	} else {
	    out_end = context->getNumEdges();
	}
	//int in_start = inrow[tid];
	//int in_end;
	//if (tid + 1 < context->getNumVertices()) {
	//    in_end = inrow[tid + 1];
	//} else {
	//    in_end = context->getNumEdges();
	//}
	//int indegree = in_end - in_start;
	//int outdegree = out_end - out_start;
	//vertex[tid] = new ChiVertex<float, float>(tid, indegree, outdegree);
	//for (int i = in_start; i < in_end; i++) {
	//    vertex[tid]->setInEdge(i - in_start, incol[i], 0.0f);
	//}
	for (int i = out_start; i < out_end; i++) {
	    vertex[tid]->setOutEdge(vertex, tid, i - out_start, col[i], INT_MAX);
	}
    }
}

__global__ void BFS(VirtVertex<int, int> **vertex, GraphChiContext* context, int iteration) {
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if (tid < context->getNumVertices()) {
        if (iteration == 0) {
            if (tid == 0) {
                ((ChiVertex<int, int> *)vertex[tid])->setValueConcrete(0);
                int numOutEdge;
                numOutEdge = ((ChiVertex<int, int> *)vertex[tid])->numOutEdgesConcrete();
                for (int i = 0; i < numOutEdge; i++) {
                    ChiEdge<int> * outEdge;
                    outEdge = ((ChiVertex<int, int> *)vertex[tid])->getOutEdgeConcrete(i);
                    ((Edge<int> *)outEdge)->setValueConcrete(1);
                }
            }
        } else {
            int curmin;
            curmin = ((ChiVertex<int, int> *)vertex[tid])->getValueConcrete();
            int numInEdge;
            numInEdge = ((ChiVertex<int, int> *)vertex[tid])->numInEdgesConcrete();
            for (int i = 0; i < numInEdge; i++) {
                ChiEdge<int> * inEdge;
                inEdge = ((ChiVertex<int, int> *)vertex[tid])->getInEdgeConcrete(i);
                curmin = min(curmin, ((Edge<int> *)inEdge)->getValueConcrete());
            }
            int vertValue;
            vertValue = ((ChiVertex<int, int> *)vertex[tid])->getValueConcrete();
            if (curmin < vertValue) {
                ((ChiVertex<int, int> *)vertex[tid])->setValueConcrete(curmin);
                int numOutEdge;
                numOutEdge = ((ChiVertex<int, int> *)vertex[tid])->numOutEdgesConcrete();
                for (int i = 0; i < numOutEdge; i++) {
                    ChiEdge<int> * outEdge;
                    outEdge = ((ChiVertex<int, int> *)vertex[tid])->getOutEdgeConcrete(i);
                    int edgeValue;
                    edgeValue = ((Edge<int> *)outEdge)->getValueConcrete();
                    if (edgeValue > curmin + 1){
                        ((Edge<int> *)outEdge)->setValueConcrete(curmin + 1);
                    }
                }
            }
        }
    }
}

__global__ void copyBack(VirtVertex<int, int> **vertex, GraphChiContext* context,
	int *index)
{
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if (tid < context->getNumVertices()) {
        index[tid] = vertex[tid]->getValue();
    }
}
