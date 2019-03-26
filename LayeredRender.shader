// Shader "Custom/LayeredRender"
// {
//     Properties
//     {
//         _Color ("Color", Color) = (1,1,1,1)
//         _MainTex ("Albedo (RGB)", 2D) = "white" {}
//         _Glossiness ("Smoothness", Range(0,1)) = 0.5
//         _Metallic ("Metallic", Range(0,1)) = 0.0
//     }
//     SubShader
//     {
//         Tags { "RenderType"="Opaque" }
//         LOD 200

//         CGINCLUDE
//         #include "./Code/ComputeShaders/Bake.cginc"
//         ENDCG

        

//         Pass {
//         CGPROGRAM
//         // Physically based Standard lighting model, and enable shadows on all light types
//         #pragma surface surf Standard fullforwardshadows
//         #pragma exclude_renderers nomrt
//         #pragma multi_compile_prepassfinal
//         #pragma multi_compile ___ UNITY_HDR_ON
//         // #pragma exclude_renderers d3d11
//         // Use shader model 3.0 target, to get nicer looking lighting
//         #pragma target 5.0

//         sampler2D _MainTex;
//         uniform int _BufferPtr;
//         uniform StructuredBuffer<int> _Buffer;

//         struct Input
//         {
//             float2 uv_MainTex;
//         };

//         half _Glossiness;
//         half _Metallic;
//         fixed4 _Color;
        

//         uniform int _Layer;

//         // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
//         // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
//         // #pragma instancing_options assumeuniformscaling
//         UNITY_INSTANCING_BUFFER_START(Props)
//             // put more per-instance properties here
//         UNITY_INSTANCING_BUFFER_END(Props)

//         void surf (Input IN, inout SurfaceOutputStandard o)
//         {
//             float2 uv = IN.uv_MainTex;

//             uint2 xz = uint2(uv * 32);
//             // Albedo comes from a texture tinted by color
//             // fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
//         #ifdef SHADER_API_D3D11
//             uint3 m = uint3(x.x, _Layer, x.z);
//             int index = BufferToIndex(VoxelToBuffer(m));
//             float4 color = UnpackColor(_Buffer[_BufferPtr + index]);
//         #else
//             float4 color = float4(1.0, 0.0, 1.0, 1.0);
//         #endif
//             o.Albedo = color;//float4(xz / 32.0, _Layer / 32.0, 1.0);
//             // Metallic and smoothness come from slider variables
//             o.Metallic = _Metallic;
//             o.Smoothness = _Glossiness;
//             o.Alpha = color.a;
//         }
//         ENDCG
//     }
//     FallBack "Diffuse"
// }
