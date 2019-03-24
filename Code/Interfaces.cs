using UnityEngine;

namespace VoxelRaymarching
{
    public interface IBakerTaskBuilder
    {
        IBakerTaskBuilder AddLayer(ChunkVolumeLayer layer);
    }
    
    public interface IVolumeBaker
    {
        IBakerTaskBuilder CreateTask(Material targetMaterial);
        void DeployTask(IBakerTaskBuilder task);
    }
}