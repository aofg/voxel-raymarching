Shader "Unlit/BufferRendererNormal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VolumeSize ("Size", Vector) = (32,1,1,1)
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "DisableBatching" = "True"}
        LOD 100
        Lighting Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #define SIZE 32

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _VolumeSize;
            
            int4 _VolumeOffset;
            int4 _VolumeRotate;
            int3 _VolumePivot;
            
            float4x4 _VolumeMatrix;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 bufferToVoxel(float2 uv) {
                uv *= float2(SIZE, 1) * SIZE;
                
                return float3(
                    // x
                    floor(uv.x % SIZE),
                    floor(uv.x / SIZE),
                    32.0 - floor(uv.y)
                );
            }

            float2 voxelToUV(float3 xyz, float3 size) {
                xyz /= size;

                return float2(
                    // u
                    xyz.x / size.y + xyz.y,
                    xyz.z
                );
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 xyz = bufferToVoxel(i.texcoord) - _VolumeOffset.xyz;
//                xyz -= max(int3(0, 0, 0), int3(SIZE, SIZE, SIZE) - int3(_VolumeSize)) / 2;
//                xyz -= _VolumePivot;
                xyz.x = lerp(xyz.x, SIZE - xyz.x, _VolumeOffset.w);
                xyz.z = lerp(xyz.z, SIZE - xyz.z, _VolumeRotate.w); 
//                xyz += _VolumePivot;
                
                for (int r = 0; r < _VolumeRotate.y % 4; r++) {
                    xyz -= _VolumePivot;
                    xyz = float3(xyz.z, xyz.y, -xyz.x);
                    xyz += _VolumePivot;  
                }
                
                for (int r = 0; r < _VolumeRotate.x % 4; r++) {
                    xyz -= _VolumePivot;
                    xyz = float3(xyz.x, xyz.z, -xyz.y);
                    xyz += _VolumePivot;  
                }
                
                for (int r = 0; r < _VolumeRotate.z % 4; r++) {
                    xyz -= _VolumePivot;
                    xyz = float3(xyz.y, -xyz.x, xyz.z);
                    xyz += _VolumePivot;  
                }
                
                xyz = mul(_VolumeMatrix, xyz);
                
                if (xyz.x > _VolumeSize.x || 
                    xyz.y > _VolumeSize.y || 
                    xyz.z > _VolumeSize.z ||
                    xyz.x < 0 ||
                    xyz.y < 0 ||
                    xyz.z < 0) {
                    discard;
                }  
                    
                float2 uv = voxelToUV(xyz, _VolumeSize);
                float3 m = 1 - step(_VolumeSize, xyz);
                float mask = min(m.x, min(m.y, m.z));
                float4 col = tex2D(_MainTex, uv);
                clip(min(mask, col.a) - 0.5);
                return col;
            }
            ENDCG
        }
    }
}
