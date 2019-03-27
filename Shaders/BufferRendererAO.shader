Shader "Unlit/BufferRendererAO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "DisableBatching" = "True"}
        LOD 100
        Lighting Off
        Cull Off
        ZWrite On
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            uniform sampler2D _MainTex;
            
            float4 frag (v2f_img i) : COLOR
            {
                float2 uv = float2(i.uv.x, 1.0 - i.uv.y);
                uv = i.uv;
                float4 buffer = tex2D(_MainTex, uv);
                float4 col = buffer * 0.5;
                col.a = buffer.a;
                return col;
            }
            ENDCG
        }
    }
}
