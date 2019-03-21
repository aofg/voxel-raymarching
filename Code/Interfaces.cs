using UnityEngine;

namespace VoxelRaymarching
{
    public interface IBakerTaskBuilder
    {
        IBakerTaskBuilder AddLayer(ChunkVolumeLayer layer);
        void Bake();
    }
    
    public interface IVolumeBaker
    {
        IBakerTaskBuilder CreateTask(Material targetMaterial);
    }
}