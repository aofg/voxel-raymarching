using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Profiling;

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

    [RequireComponent(typeof(Camera))]
    public class ChunkVolumeBaker : MonoBehaviour
    {
        private Material _material;
        private Material _aoMaterial;
        private Material _solidMaterial;
        private Mesh _quadMesh;

        private RenderTexture _temporaryVolumeBuffer;
        private Queue<KeyValuePair<RenderTexture, ChunkVolumeLayer[]>> _renderTasks =
            new Queue<KeyValuePair<RenderTexture, ChunkVolumeLayer[]>>();
        private HashSet<RenderTexture> _updatingSet = new HashSet<RenderTexture>();

        private KeyValuePair<RenderTexture, ChunkVolumeLayer[]> _task;

        private Camera _cachedCamera;

        public Material BakerMaterial
        {
            get
            {
                if (_material == null)
                {
                    _material = CreateBakingMaterial();
                }

                return _material;
            }
        }

        public Material AmbientOcclusionMaterial
        {
            get
            {
                if (_aoMaterial == null)
                {
                    _aoMaterial = CreateAOMaterial();
                }

                return _aoMaterial;
            }
        }
        
        public Material SolidMaterial
        {
            get
            {
                if (_solidMaterial == null)
                {
                    _solidMaterial = CreateSolidMaterial();
                }

                return _solidMaterial;
            }
        }

        private Camera Camera
        {
            get
            {
                if (_cachedCamera == null)
                {
                    _cachedCamera = CreateBakerCamera();
                }

                return _cachedCamera;
            }
        }

        private Mesh QuadMesh
        {
            get
            {
                if (_quadMesh == null)
                {
                    _quadMesh = CreateQuadMesh();
                }

                return _quadMesh;
            }
        }

        private Material CreateSolidMaterial()
        {
            var mat = new Material(Shader.Find("Unlit/BufferRendererSolidColor"));
            mat.SetColor("_Color", new Color(.5f, .5f, 1.0f, 1.0f));
            mat.SetPass(0);
            return mat;
        }

        private Material CreateBakingMaterial()
        {
            var mat = new Material(Shader.Find("Unlit/BufferRendererNormal"));
            mat.SetPass(0);
            return mat;
        }

        private Material CreateAOMaterial()
        {
            var mat = new Material(Shader.Find("Unlit/BufferRendererAO"));
            mat.SetPass(0);
            return mat;
        }

        private Mesh CreateQuadMesh()
        {
            var quad = new Mesh();
            var dirs = new Vector3(1f, -1f, 0f);
            var size = new Vector3(16f, 0.5f, 0f);
            quad.vertices = new[]
            {
                size.xyz().mul(dirs.yxz()), // top left
                size.xyz().mul(dirs.xxz()), // top right
                size.xyz().mul(dirs.xyz()), // bottom right
                size.xyz().mul(dirs.yyz()), // bottom left
            };

            quad.triangles = new[]
            {
                0, 1, 3,
                3, 1, 2
//                3, 1, 0,
//                2, 1, 3
            };

            quad.normals = new[]
            {
                dirs.zzy(),
                dirs.zzy(),
                dirs.zzy(),
                dirs.zzy()
            };

            quad.uv = new[]
            {
                dirs.zz(),
                dirs.xz(),
                dirs.xx(),
                dirs.zx()
            };

            return quad;
        }


        private Camera CreateBakerCamera()
        {
//            var bakerCameraGameObject = new GameObject("-Baker Camera");
//            bakerCameraGameObject.hideFlags = HideFlags.HideAndDontSave;
            var bakerCameraComponent = GetComponent<Camera>();
            bakerCameraComponent.cullingMask = ~0;
            bakerCameraComponent.nearClipPlane = -100;
            bakerCameraComponent.farClipPlane = 100;
            bakerCameraComponent.clearFlags = CameraClearFlags.SolidColor;
            bakerCameraComponent.backgroundColor = new Color(0.5f, 0.5f, 1f, 0.0f);
            bakerCameraComponent.orthographic = true;
            bakerCameraComponent.orthographicSize = 0.5f; // One unit height (to simplify mesh dimensions calculation)
            bakerCameraComponent.enabled = false;

            return bakerCameraComponent;
        }

        
        /// <summary>
        /// Renders layers to target volume texture
        /// </summary>
        /// <param name="layers">Collection of layers</param>
        /// <param name="target">Target buffer texture</param>
        public bool Bake(ChunkVolumeLayer[] layers, RenderTexture target)
        {
            if (_updatingSet.Contains(target))
            {
                //skip before last end
                return false;
            }

            Debug.LogFormat("Enqueue new buffer {0} ({1} layers)", target.name, layers.Length);
            _updatingSet.Add(target);
            _renderTasks.Enqueue(new KeyValuePair<RenderTexture, ChunkVolumeLayer[]>(target, layers));
            
            return true;
        }

        void Awake()
        {
            _temporaryVolumeBuffer = new RenderTexture(1024, 32, 0, RenderTextureFormat.ARGB32);
            _temporaryVolumeBuffer.Create();
            QuadMesh.name = "test";
        }

        void Update()
        {
            while (_renderTasks.Count > 0)
            {
                _task = _renderTasks.Dequeue();
                _updatingSet.Remove(_task.Key);
                Camera.targetTexture = _temporaryVolumeBuffer;
                Camera.Render();
            }
        }

//        private void OnRenderImage(RenderTexture src, RenderTexture dest)
//        {
//            if (_task.Key == null || _task.Value == null)
//            {
//                return;
//            }
//
//            AmbientOcclusionMaterial.SetPass(0);
//            AmbientOcclusionMaterial.mainTexture = RenderTexture.active;
//            Graphics.Blit(src, dest);
////            Graphics.DrawMeshNow(QuadMesh, new Vector3(0, 0, -1), Quaternion.identity);
//        }

        private void OnPostRender()
        {
            if (_task.Key == null || _task.Value == null)
            {
                return;
            }

            Camera.targetTexture = _task.Key;
//            _task.Key.GenerateMips();
//            AmbientOcclusionMaterial.mainTexture = _temporaryVolumeBuffer;
//            Graphics.DrawMeshNow(QuadMesh, new Vector3(0, 0, -1), Quaternion.identity);
//            Graphics.Blit(_temporaryVolumeBuffer, _task.Key, AmbientOcclusionMaterial, 0);
        }


        private void OnPreCull()
        {
            if (_task.Key == null || _task.Value == null)
            {
                return;
            }

            Debug.LogFormat("Render buffer {0}", _task.Key.name);
            // create fixed reference to avoid calling getter function
            var camera = Camera;
            if (Camera.current != camera)
            {
                return;
            }

            Profiler.BeginSample("BakeChunk");
            var layers = _task.Value;
            var depth = 0;
            
            // clear?
//            SolidMaterial.SetPass(0);
//            Graphics.DrawMesh(QuadMesh, new Vector3(0, 0, 99), Quaternion.identity,);

            BakerMaterial.SetPass(0);

            foreach (var layer in layers)
            {
                Profiler.BeginSample("BakeChunk.Layer");
                var props = new MaterialPropertyBlock();
                
                props.SetVector("_VolumeOffset",
                    new Vector4(layer.Offset.x, layer.Offset.y, layer.Offset.z, layer.FlipHorizontal ? 1 : 0));
                props.SetVector("_VolumeRotate",
                    new Vector4(layer.Rotate.x, layer.Rotate.y, layer.Rotate.z, layer.FlipVertical ? 1 : 0));
                props.SetVector("_VolumeSize",
                    new Vector4(layer.VolumeSize.x, layer.VolumeSize.y, layer.VolumeSize.z, 0));
                props.SetVector("_VolumePivot",
                    new Vector4(layer.VolumePivot.x, layer.VolumePivot.y, layer.VolumePivot.z, 0));
                props.SetMatrix("_VolumeMatrix", layer.VolumeTRS);
                props.SetTexture("_MainTex", layer.LayerVolume);

                Graphics.DrawMesh(QuadMesh, Matrix4x4.Translate(new Vector3(0, 0, depth++)), BakerMaterial, 0, camera, 0, props);

//                Graphics.DrawMesh(QuadMesh, new Vector3(0, 0, depth++), Quaternion.identity);
                Profiler.EndSample();
            }

            // bake ao
//            AmbientOcclusionMaterial.mainTexture = task.Key;
//            AmbientOcclusionMaterial.SetPass(0);
//            Graphics.DrawMeshNow(QuadMesh, new Vector3(0, 0, depth++), Quaternion.identity);

            Profiler.EndSample();
        }
    }
}
