/*
 * Copyright (C) 2019 Aler Denisov <aler@aofg.cc>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


using System;
using System.Linq;
using Unity.Mathematics;
using UnityEngine;

namespace VoxelRaymarching
{
    [ExecuteInEditMode]
    public class RenderTextureToBuffer : MonoBehaviour
    {
        public const int SHADER_BATCH = 32;
        public const int SHADER_BATCH_2 = 1024; // 32*32
        
        [System.Serializable]
        public class TextureLayer
        {
            public Texture Layer;
            public int3 Size;
            public int3 Offset;
            public int3 Rotate;
            public int3 Pivot;
        }

        public TextureLayer[] Layers;
        public ComputeShader ClearShader;
        public ComputeShader BlendShader;

        private ComputeBuffer cb;

        private void OnEnable()
        {
            cb = new ComputeBuffer(2 * 32 * 32 * 32, sizeof(int));
        }

        private void OnDisable()
        {
            cb?.Dispose();
        }

        private void Update()
        {
            var mr = GetComponent<MeshRenderer>();
            if (!mr)
            {
                enabled = false;
                throw new NullReferenceException("Meshrenderer not found");
            }

            if (Layers.Length == 0)
            {
                enabled = false;
                throw new NullReferenceException("Layers is required");
            }

            if (Layers.Any(l => l.Layer == null))
            {
                enabled = false;
                throw new NullReferenceException("Layer textures is required");
            }
            
            ClearShader.SetBuffer(0, "output", cb);
            ClearShader.SetInt("length", 32 * 32 * 32);
            ClearShader.SetInt("ptr", 32 * 32 * 32);
            ClearShader.Dispatch(0, 32, 1, 1); // 1024 cols

            BlendShader.SetBuffer(0, "output", cb);
            BlendShader.SetInt("ptr", 32 * 32 * 32);
            
            foreach (var layer in Layers)
            {
                BlendShader.SetInts("inputOffset", layer.Offset.x, layer.Offset.y,  layer.Offset.z);
                BlendShader.SetInts("inputRotate", layer.Rotate.x, layer.Rotate.y,  layer.Rotate.z);
                BlendShader.SetInts("inputSize", layer.Size.x, layer.Size.y,  layer.Size.z);
                BlendShader.SetMatrix("inputTRS", Matrix4x4.Rotate(Quaternion.Euler((float3) layer.Rotate)));
                BlendShader.SetInts("inputPivot", layer.Pivot.x, layer.Pivot.y,  layer.Pivot.z);
                BlendShader.SetTexture(0, "input", layer.Layer);
                BlendShader.Dispatch(0, 1, 1, SHADER_BATCH);
            }
            
//            CopyShader.SetInts("resolution", Texture.width, Texture.height);
//            CopyShader.SetInt("ptrDest", Texture.width * Texture.height * 5);
//            
//            CopyShader.SetBuffer(0, "output", cb);
//            CopyShader.SetTexture(0, "input", Texture);
//            CopyShader.Dispatch(0, 1 + Texture.width / SHADER_BATCH, 1 + Texture.height / SHADER_BATCH, 1);

            if (Application.isPlaying)
            {
                mr.material.SetBuffer("_Buffer", cb);
                mr.material.SetInt("_BufferPtr", 32 * 32 * 32);
            }
            else
            {
                mr.sharedMaterial.SetBuffer("_Buffer", cb);
                mr.sharedMaterial.SetInt("_BufferPtr", 32 * 32 * 32);
            }

//            enabled = false;
        }
    }
}