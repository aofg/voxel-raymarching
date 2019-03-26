using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

namespace VoxelRaymarching
{
    public class BufferVolumeTaskBuilder // : IBakerTaskBuilder
    {
        private const int MAX_LAYERS_COUNT = 64;
        
        internal readonly ChunkVolumeLayer[] layers;
        internal uint layersCount;
        internal uint pointer;
        internal ComputeBuffer target;


        public BufferVolumeTaskBuilder()
        {
            layers = new ChunkVolumeLayer[MAX_LAYERS_COUNT];
        }

        internal void Initialize(ComputeBuffer target, uint pointer)
        {
            layersCount = 0;
            this.target = target;
            this.pointer = pointer;
        }
        
        public BufferVolumeTaskBuilder AddLayer(ChunkVolumeLayer layer)
        {
            layers[layersCount++] = layer;
            return this;
        }

//        public void Bake()
//        {
//        }
    }
    
    public class BufferVolumeBaker : MonoBehaviour
    {
        public const int SIDE = 32;
        public const int SIDE_2 = 32 * 32;
        public const int SIDE_3 = 32 * 32 * 32;
        
        public ComputeShader ClearShader;
        public ComputeShader BlendShader;
        
        private Stack<BufferVolumeTaskBuilder> _pooledBuilders;
        private Queue<BufferVolumeTaskBuilder> _enqueueTasks;
        private int itt;

        public BufferVolumeBaker()
        {
            _pooledBuilders = new Stack<BufferVolumeTaskBuilder>();
            _enqueueTasks = new Queue<BufferVolumeTaskBuilder>();
        }

        void Update()
        {
            var batch = 8;

            while (_enqueueTasks.Count > 0 && batch > 0)
            {
                var task = _enqueueTasks.Dequeue();
                InternalBake(task.layers, task.layersCount, task.target, task.pointer);
                ReleaseBuilder(task);
                batch--;
            }
        }

        public BufferVolumeTaskBuilder CreateTask(ComputeBuffer buffer, uint pointer)
        {
            var task = GetNextBuilder();
            task.Initialize(buffer, pointer);
            return task;
        }

        public void DeployTask(BufferVolumeTaskBuilder task)
        {
            _enqueueTasks.Enqueue(task);
        }

        private BufferVolumeTaskBuilder GetNextBuilder()
        {
            if (_pooledBuilders.Count > 0)
            {
                var builder = _pooledBuilders.Pop();
                return builder;
            }
            
            return new BufferVolumeTaskBuilder();
        }

        private void InternalBake(ChunkVolumeLayer[] layers, uint layersCount, ComputeBuffer cb, uint pointer)
        {
            ClearShader.SetBuffer(0, "output", cb);
            ClearShader.SetInt("length", 32 * 32 * 32);
            ClearShader.SetInt("ptr", unchecked((int)pointer));
            ClearShader.Dispatch(0, 32, 1, 1); // 1024 cols

            BlendShader.SetBuffer(0, "output", cb);
            BlendShader.SetInt("ptr", unchecked((int)pointer));

            for (var index = 0; index < layersCount; index++)
            {
                var layer = layers[index];
                
                BlendShader.SetInts("inputOffset", layer.Offset.x, layer.Offset.y,  layer.Offset.z);
                BlendShader.SetInts("inputSize", layer.VolumeSize.x, layer.VolumeSize.y,  layer.VolumeSize.z);
                BlendShader.SetMatrix("inputTRS", Matrix4x4.Rotate(Quaternion.Euler((float3) layer.Rotate)));
                BlendShader.SetInts("inputPivot", layer.VolumePivot.x, layer.VolumePivot.y,  layer.VolumePivot.z);
                BlendShader.SetTexture(0, "input", layer.LayerVolume);
                BlendShader.Dispatch(0, 1, 1, SIDE);
            }
        }

        private void ReleaseBuilder(BufferVolumeTaskBuilder bufferVolumeTaskBuilder)
        {
            bufferVolumeTaskBuilder.target = null;
            _pooledBuilders.Push(bufferVolumeTaskBuilder);
        }
    }
}