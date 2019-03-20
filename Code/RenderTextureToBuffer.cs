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