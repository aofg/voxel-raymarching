using Unity.Mathematics;
using UnityEngine;

namespace VoxelRaymarching
{
    [System.Serializable]
    [CreateAssetMenu(fileName = "Volume.asset", menuName = "Volume Asset")]
    public class VolumeAsset : ScriptableObject
    {
        public Texture2D VolumeTexture;
        public int3 VolumeSize;
        public int3 VolumePivot;
    }
}