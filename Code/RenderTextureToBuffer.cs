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
using System.Collections.Generic;
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
            var children = transform.GetComponentsInChildren<Transform>();
            for (var index = 0; index < children.Length; index++)
            {
                if (children[index] == transform)
                {
                    continue;
                }
                
                if (Application.isPlaying)
                {
                    Destroy(children[index].gameObject);
                }
                else
                {
                    DestroyImmediate(children[index].gameObject);
                    
                }
            }
            
            var list = new List<Vector3>();
//            list.Add(new Vector3(1.001f, 0.001f, 0f).normalized);
//            list.Add(new Vector3(0.001f, 1.001f, 0f).normalized);
//            list.Add(new Vector3(0.001f, 0f, 1.001f).normalized);
//            list.Add(-(new Vector3(1.001f, 0.001f, 0f).normalized));
//            list.Add(-(new Vector3(0.001f, 1.001f, 0f).normalized));
//            list.Add(-(new Vector3(0.001f, 0f, 1.001f).normalized));
            
            var max = 64;
            while (max-- > 0)
            {
                var ray = UnityEngine.Random.onUnitSphere;
                ray.y = Mathf.Abs(ray.y);
                list.Add(ray);
            }
            

            Shader.SetGlobalFloatArray("_UniformRays", list.SelectMany(v => new[] {v.x, v.y, v.z}).ToArray());

            if (Application.isPlaying)
            {
                enabled = false;
            }

            cb = new ComputeBuffer(2 * 32 * 32 * 32, sizeof(int));
            

            var shader = Shader.Find("Unlit/LayeredUnlit");

            var tmp = GameObject.CreatePrimitive(PrimitiveType.Quad);
            if (Application.isPlaying)
            {
                Destroy(tmp.GetComponent<Collider>());
            }
            else
            {
                DestroyImmediate(tmp.GetComponent<Collider>());
            }

            for (int i = 0; i < 32; i++)
            {
                var layer = Instantiate(tmp, transform);
                layer.hideFlags = HideFlags.HideAndDontSave;
                
                layer.transform.localPosition = new Vector3(0.5f, i * (1f / 32f), 0.5f);
                layer.transform.localRotation = Quaternion.Euler(90, 0, 0);
                var layerMat = new Material(shader);
                layerMat.SetInt("_Layer", i);
                layerMat.SetBuffer("_Buffer", cb);
                layerMat.SetInt("_BufferPtr", 32 * 32 * 32);

                layer.GetComponent<MeshRenderer>().material = layerMat;
            }
            if (Application.isPlaying)
            {
                Destroy(tmp);
            }
            else
            {
                DestroyImmediate(tmp);
            }
            
            Layers[1].Rotate = new int3(0, UnityEngine.Random.Range(-90, 90), 0);
            
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
        }

        private void OnDisable()
        {
            cb?.Dispose();
        }
    }
}