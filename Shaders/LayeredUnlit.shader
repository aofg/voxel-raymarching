Shader "Unlit/LayeredUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma exclude_renderers nomrt
            #pragma multi_compile_prepassfinal
            #pragma multi_compile ___ UNITY_HDR_ON

            #pragma target 4.5

            #include "UnityCG.cginc"
            #include "./Code/ComputeShaders/Bake.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 xyz : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform int _Layer;
            uniform int _BufferPtr;
            uniform StructuredBuffer<int> _Buffer;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.xyz = mul(unity_ObjectToWorld, v.vertex) * 32;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // float2 uv = i.uv;
                // uint2 xz = uint2(uv * 32);
                uint3 m = floor(i.xyz);
                int index = BufferToIndex(VoxelToBuffer(m));
                float4 col = UnpackColor(_Buffer[_BufferPtr + index]);
                // float4 col = float4(i.worldPos, 1.0);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                clip(col.a - 0.5);
                return col;
            }
            ENDCG
        }
    }
}
