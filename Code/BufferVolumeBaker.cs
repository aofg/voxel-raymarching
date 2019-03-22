using System.Collections.Generic;
using UnityEngine;

namespace VoxelRaymarching
{
    public class BufferVolumeTaskBuilder : IBakerTaskBuilder
    {
        private const int MAX_LAYERS_COUNT = 64;
        
        private ChunkVolumeLayer[] _layers;
        private int _layersCount;
        private readonly BufferVolumeBaker _baker;
        private Material _target;

        public BufferVolumeTaskBuilder(BufferVolumeBaker baker)
        {
            _layers = new ChunkVolumeLayer[MAX_LAYERS_COUNT];
            _baker = baker;
        }

        internal void Initialize(Material target)
        {
            _layersCount = 0;
            _target = target;
        }
        
        public IBakerTaskBuilder AddLayer(ChunkVolumeLayer layer)
        {
            _layers[_layersCount++] = layer;
            
            return this;
        }

        public unsafe void Bake()
        {
            _baker.InternalBake(_layers, _layersCount, _target);

            // release to allow GC make dirty work :D
            _target = null;
            
            _baker.ReleaseBuilder(this);
        }
    }
    
    public class BufferVolumeBaker : IVolumeBaker
    {
        private Stack<BufferVolumeTaskBuilder> _pooledBuilders;

        public BufferVolumeBaker()
        {
            _pooledBuilders = new Stack<BufferVolumeTaskBuilder>();
        }
        
        public IBakerTaskBuilder CreateTask(Material targetMaterial)
        {
            var task = GetNextBuilder();
            task.Initialize(targetMaterial);
            return task;
        }

        private BufferVolumeTaskBuilder GetNextBuilder()
        {
            if (_pooledBuilders.Count > 0)
            {
                var builder = _pooledBuilders.Pop();
                return builder;
            }
            
            return new BufferVolumeTaskBuilder(this);
        }

        internal void InternalBake(ChunkVolumeLayer[] layers, int layersCount, Material target)
        {
            
        }

        internal void ReleaseBuilder(BufferVolumeTaskBuilder bufferVolumeTaskBuilder)
        {
            _pooledBuilders.Push(bufferVolumeTaskBuilder);
        }
    }
}