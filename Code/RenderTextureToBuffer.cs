using System;
using UnityEngine;

namespace VoxelRaymarching
{
    [ExecuteInEditMode]
    public class RenderTextureToBuffer : MonoBehaviour
    {
        private const int SHADER_BATCH = 32;
        public Texture Texture;
        public ComputeShader CopyShader;
        private ComputeBuffer cb;
        
        private void OnEnable()
        {
            var mr = GetComponent<MeshRenderer>();
            if (!mr)
            {
                enabled = false;
                throw new NullReferenceException("Meshrenderer not found");
            }

            if (!Texture)
            {
                enabled = false;
                throw new NullReferenceException("Texture isn't assigned");
            }
            

//            if (!Texture.isReadable)
//            {
//                enabled = false;
//                throw new NullReferenceException("Texture not readable");
//            }

            cb?.Dispose();
            
            cb = new ComputeBuffer(Texture.width * Texture.height * 32 * 32 * 5, sizeof(int));
            CopyShader.SetInts("resolution", Texture.width, Texture.height);
            CopyShader.SetInt("ptrDest", Texture.width * Texture.height * 5);
            
            CopyShader.SetBuffer(0, "output", cb);
            CopyShader.SetTexture(0, "input", Texture);
            CopyShader.Dispatch(0, 1 + Texture.width / SHADER_BATCH, 1 + Texture.height / SHADER_BATCH, 1);

            if (Application.isPlaying)
            {
                mr.material.SetBuffer("_Buffer", cb);
                mr.material.SetInt("_BufferPtr", Texture.width * Texture.height * 5);
            }
            else
            {
                mr.sharedMaterial.SetBuffer("_Buffer", cb);
                mr.sharedMaterial.SetInt("_BufferPtr", Texture.width * Texture.height * 5);
            }

            enabled = false;
        }
    }
}