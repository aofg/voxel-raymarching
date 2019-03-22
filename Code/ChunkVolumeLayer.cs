using Unity.Mathematics;
using UnityEngine;

namespace VoxelRaymarching
{
    [System.Serializable]
    public struct ChunkVolumeLayer
    {
        public enum LayerBlendingMode : byte
        {
            Normal,
            Subtractive,
            Colorize,
            Projection
        }
        
        public LayerBlendingMode BlendingMode;
        public bool FlipHorizontal;
        public bool FlipVertical;
        public int3 Rotate;
        public int3 Offset;
        
        public Texture2D LayerVolume;
        public int3 VolumeSize;
        public int3 VolumePivot;
        public Matrix4x4 VolumeTRS;
    }
}