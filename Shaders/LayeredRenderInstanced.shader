Shader "Unlit/LayeredUnlitInstanced"
{
	Properties
	{
	}

	SubShader
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		LOD 100

		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#pragma instancing_options procedural:setup
			
			#include "UnityCG.cginc"
            #include "./Include/Bake.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;

				float4 vertex : SV_POSITION;
				float3 xyz : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			StructuredBuffer<uint> _AllocationMap;
			StructuredBuffer<uint> _Buffer;
			StructuredBuffer<uint> objectToWorldBuffer;
            uint layer;
            sampler2D _MainTex;
            float4 _MainTex_ST;

			UNITY_INSTANCING_BUFFER_START(Props)
			UNITY_DEFINE_INSTANCED_PROP(uint, _BufferPtr)
			UNITY_INSTANCING_BUFFER_END(Props)

			void setup()
			{

#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                uint packed = objectToWorldBuffer[unity_InstanceID];
                uint x = packed % 256;
                uint y = packed / 256 % 256;
                uint z = packed / 65536 % 256;

                unity_ObjectToWorld._11_21_31_41 = float4(1.0, 0, 0, 0);
                unity_ObjectToWorld._12_22_32_42 = float4(0, 1.0, 0, 0);
                unity_ObjectToWorld._13_23_33_43 = float4(0, 0.0, 1.0, 0);
                unity_ObjectToWorld._14_24_34_44 = float4(float(x) + 0.5, float(y) + float(layer * 2) / 32.0, float(z) + 0.5, 1.0);

				unity_WorldToObject = unity_ObjectToWorld;
				unity_WorldToObject._14_24_34 *= -1;
				unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;
#endif
			}

            uint ChunkPositionToAllocationIndex(int3 pos) {
                return pos.x + pos.z * 32 + pos.y * 1024;
            }

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);

				o.vertex = UnityObjectToClipPos(v.vertex);
                o.xyz = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;

				UNITY_TRANSFER_INSTANCE_ID(v, o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                uint allocIndex = ChunkPositionToAllocationIndex(floor(i.xyz));
                uint ptr = _AllocationMap[allocIndex];

                uint3 m = uint3(i.uv.x * 32.0, layer * 2, i.uv.y * 32.0);
                int index = BufferToIndex(VoxelToBuffer(m));
                float4 col = UnpackColor(_Buffer[ptr + index]);

                // float4 col = float4(floor(i.xyz) / 32.0, 1.0);
                clip(col.a - 0.5);
				
				return col;
			}
			ENDCG
		}
	}
}