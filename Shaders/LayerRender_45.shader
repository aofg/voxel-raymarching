Shader "Unlit/VoxelRenderForBuffer"
{
    Properties
    {
        // _Volume2D ("Volume 2D", 2D) = "white" {}
        _VolumeSize ("Size", Vector) = (8,8,8,1)
        _BufferPtr ("Memory Pointer", Int) = 0
        _AoRays ("AO Rays", Int) = 4
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "DisableBatching" = "True"
        }
        LOD 100

        CGINCLUDE
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
        #define USE_RAYMARCHING_DEPTH
        #define EPSILON 0.000001

        #include "UnityCG.cginc"
        #include "UnityPBSLighting.cginc"
        #include "./Include/Structs.cginc"
        #include "./Include/Utils.cginc"
        #include "./Include/Raymarching.cginc"
        #include "./Code/ComputeShaders/Bake.cginc"
        
        float4 _VolumeSize;
        uniform StructuredBuffer<int> _AllocationMap;
        uniform int3 _WorldSize;
        uniform int3 _ChunkSize;
        uniform int _ChunkLength;
        uniform int _BufferPtr;
        uniform StructuredBuffer<int> _Buffer;
        uniform int _AoRays;

        uniform float _UniformRays[192];

        bool getHit(in int3 m, in int ptr,  out float4 voxel) {

            // int u = m.y + m.z * _VolumeSize.x;
            // int v = m.x;
            // int index = u * _VolumeSize.x + v;////y * _VolumeSize.x * _VolumeSize.y + x;
            int index = BufferToIndex(VoxelToBuffer(uint3(m)));
            int voxelInt = _Buffer[ptr + index];

            voxel.r = (voxelInt >> 24 & 0xFF) / 256.0;
            voxel.g = (voxelInt >> 16 & 0xFF) / 256.0;
            voxel.b = (voxelInt >>  8 & 0xFF) / 256.0;
            voxel.a = (voxelInt >>  0 & 0xFF) / 256.0;

            return voxel.a > 0;
            // float2 uv = float2(
            //     // u
            //     m.y / _VolumeSize.y + (m.x + .5) / _VolumeSize.x / _VolumeSize.y,
            //     // v
            //     (m.z + 0.5) / _VolumeSize.z
            // );
            // voxel = tex2D(_Volume2D, uv);// (m + 0.5) / _VolumeSize);
            // return voxel.a > 0.5;
        }

        bool raycast(inout RaymarchInfo ray, bool passThrough = false) {
            float3 rayDir = ray.rayDir;
            float rayLength = length(rayDir);
            float3 startPos = ToLocal(ray.startPos) * _VolumeSize;
            float3 rayPos = startPos;
            float3 mapPos = floor(rayPos);
            float3 deltaDist = abs(float3(rayLength, rayLength, rayLength) / rayDir);
            float3 rayStep = sign(rayDir);
            float3 sideDist = (sign(rayDir) * (mapPos - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist; 
            float3 mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);

            bool hit = false;
            for(ray.loop = 0; ray.loop < ray.maxLoop; ray.loop++) {
                float3 m = floor(mapPos);
                bool outside = m.x < 0 || m.y < 0 || m.z < 0 || m.x >= _VolumeSize.x || m.y >= _VolumeSize.y || m.z >= _VolumeSize.z;

                if (!outside && getHit(m, _BufferPtr, ray.voxel)) { 
                    hit = true; 
                    break;
                }
                
                mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
                sideDist += mask * deltaDist;
                mapPos += mask * rayStep;
                

                if(outside) {
                    hit = false;
                    continue;
                }
            }

            ray.endPos = rayDir / dot(mask * rayDir, 1) * dot(mask * (mapPos + step(rayDir, 0) - rayPos), 1) + rayPos;
            ray.normal = -rayStep * mask;
            ray.totalLength = length(ray.endPos - startPos);

            return hit;
        }

        ENDCG

        Pass
        {
            Tags { "LightMode" = "Deferred" }

            Stencil
            {
                Comp Always
                Pass Replace
                Ref 128
            }
            CGPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma exclude_renderers nomrt
            #pragma multi_compile_prepassfinal
            #pragma multi_compile ___ UNITY_HDR_ON
            

        
        struct VertOutput
        {
            float4 pos         : SV_POSITION;
            float3 worldPos    : TEXCOORD0;
            float3 worldNormal : TEXCOORD1;
            float4 projPos     : TEXCOORD2;
            float4 lmap        : TEXCOORD3;
        #ifdef LIGHTMAP_OFF
            #if UNITY_SHOULD_SAMPLE_SH
            half3 sh           : TEXCOORD4;
            #endif
        #endif
        };

        VertOutput Vert(appdata_full v)
        {
            VertOutput o;
        #ifdef FULL_SCREEN
            o.pos = v.vertex;
        #else
            o.pos = UnityObjectToClipPos(v.vertex);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex);
            o.worldNormal = UnityObjectToWorldNormal(v.normal);
        #endif
            o.projPos = ComputeNonStereoScreenPos(o.pos);
            COMPUTE_EYEDEPTH(o.projPos.z);

        #ifndef DYNAMICLIGHTMAP_OFF
            o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
        #else
            o.lmap.zw = 0;
        #endif

        #ifndef LIGHTMAP_OFF
            o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        #else
            o.lmap.xy = 0;
            #ifndef SPHERICAL_HARMONICS_PER_PIXEL
                #if UNITY_SHOULD_SAMPLE_SH
            o.sh = 0;
            o.sh = ShadeSHPerVertex(o.worldNormal, o.sh);
                #endif
            #endif
        #endif

            return o;
        }

            GBufferOut Frag(VertOutput i, GBufferOut o)
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                RaymarchInfo ray;
                INITIALIZE_RAYMARCH_INFO(ray, i, 128, 0.001);
                bool hit = raycast(ray);

                if (!hit) {
                    discard;
                }

                float3 worldPos = ToWorld(ray.endPos / _VolumeSize);
                float3 worldNormal = ray.normal;// 2.0 * normal - 1.0;
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                SurfaceOutputStandard so;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, so);
                so.Albedo = ray.voxel.rgb;
                so.Metallic = 0.0;
                so.Smoothness = 0.2;
                so.Emission = float3(0.0, 0.0, 0.0);
                so.Alpha = 1.0;
                so.Occlusion = 1.0;// 1.0 - (shadow * 3.0);// -5.0;//shadow;// ? 0.0 : 1.0;
                so.Normal = worldNormal;

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = 0;
                gi.light.dir = half3(0, 1, 0);
                gi.light.ndotl = LambertTerm(worldNormal, gi.light.dir);


                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = worldViewDir;
                giInput.atten = 1;

            #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                giInput.lightmapUV = i.lmap;
            #else
                giInput.lightmapUV = 0.0;
            #endif

            #if UNITY_SHOULD_SAMPLE_SH
                #ifdef SPHERICAL_HARMONICS_PER_PIXEL
                giInput.ambient = ShadeSHPerPixel(worldNormal, 0.0, worldPos);
                #else
                giInput.ambient.rgb = i.sh;
                #endif
            #else
                giInput.ambient.rgb = 0.0;
            #endif

                giInput.probeHDR[0] = unity_SpecCube0_HDR;
                giInput.probeHDR[1] = unity_SpecCube1_HDR;

            #if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
                giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
            #endif

            #if UNITY_SPECCUBE_BOX_PROJECTION
                giInput.boxMax[0] = unity_SpecCube0_BoxMax;
                giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
                giInput.boxMax[1] = unity_SpecCube1_BoxMax;
                giInput.boxMin[1] = unity_SpecCube1_BoxMin;
                giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
            #endif

                LightingStandard_GI(so, giInput, gi);

                o.emission = LightingStandard_Deferred(so, worldViewDir, gi, o.diffuse, o.specular, o.normal);
                
            #ifndef UNITY_HDR_ON
               o.emission.rgb = exp2(-o.emission.rgb);
            #endif

                UNITY_OPAQUE_ALPHA(o.diffuse.a);

                o.depth = EncodeDepth(worldPos);

                
            //     float ambientHits = 0.0;
            //     for (uint rayIndex = 0; rayIndex < _AoRays; rayIndex++) {
            //         RaymarchInfo aoRay;
            //         INITIALIZE_RAYMARCH_INFO(aoRay, i, 50, 0.001);
            //         aoRay.startPos = worldPos - ray.rayDir * 0.001;
            //         aoRay.rayDir = float3(
            //             _UniformRays[rayIndex * 3 + 0],
            //             _UniformRays[rayIndex * 3 + 1],
            //             _UniformRays[rayIndex * 3 + 2]
            //         );

            //         ambientHits += raycast(aoRay, true) ? pow(max(0.0, 100.0 - aoRay.totalLength) / 100.0, 1.0) / _AoRays : 0.0;
            //     }

            //     float ao = 1.0 - min(1.0, pow(ambientHits, 3.5)) * 0.65;
            //     // o.diffuse = o.emission = float4(ao, ao, ao, 0.0);

            //     float4 ambient = float4(0,0,0,0);
            // #if UNITY_SHOULD_SAMPLE_SH
            //     #ifdef SPHERICAL_HARMONICS_PER_PIXEL
            //     ambient = ShadeSHPerPixel(worldNormal, 0.0, worldPos);
            //     #else
            //     ambient.rgb = i.sh;
            //     #endif
            // #else
            //     ambient.rgb = 0.0;
            // #endif


            //     float shadowPower = 0.0;

            //     float3 lightpos = worldPos + lightDir * 20;

            //     for (uint rayIndex = 0; rayIndex < _AoRays; rayIndex++) {
            //         RaymarchInfo lightRay;
            //         INITIALIZE_RAYMARCH_INFO(lightRay, i, 50, 0.001);
            //         float3 offset = float3(
            //             _UniformRays[rayIndex * 3 + 0],
            //             _UniformRays[rayIndex * 3 + 1],
            //             _UniformRays[rayIndex * 3 + 2]
            //         );
            //         float3 lightDir = normalize(lightpos + offset * 7.5 - worldPos);
            //         lightRay.startPos = worldPos + lightDir * 0.1;
            //         lightRay.rayDir = lightDir;
            //         float hit = float(raycast(lightRay, true));
            //         float rayPower = max(0.0, 100.0 - lightRay.totalLength) / 100.0;
            //         shadowPower += hit * rayPower;
            //     }
            //     // float3 occluderWorldPos = ToWorld(lightRay.endPos / _VolumeSize);
            //     // float distance = pow(length(occluderWorldPos - worldPos) / 3.5, 0.9 - (ambient) * 0.45);
            //     // float dcof = max(0, 1.0 - distance);
            //     // float ndot = abs(dot(worldNormal, lightDir));//gi.light.ndotl;
            //     // float shadow = 1.0 * lightHit * ndot * dcof * (0.65 + ambient * 0.2);

            //     float shadow = 1.0 - pow(shadowPower / _AoRays, 3.5) * 0.5;//1.0 - (shadowPower / _AoRays);

            //     o.specular.rgb *= ao * shadow;
            //     o.diffuse.rgb *= ao * shadow;
            //     o.emission.rgb *= ao * shadow;

                
            //     RaymarchInfo lightRay;
            //     INITIALIZE_RAYMARCH_INFO(lightRay, i, 128, 0.001);
            //     lightRay.startPos = worldPos + lightDir * 0.00001;
            //     lightRay.rayDir = lightDir;
            //     bool lightHit = raycast(lightRay, true);
            //     float3 occluderWorldPos = ToWorld(lightRay.endPos / _VolumeSize);
            //     float distance = pow(length(occluderWorldPos - worldPos) / 3.5, 0.9 - (giInput.ambient) * 0.45);
            //     float dcof = max(0, 1.0 - distance);
            //     float ndot = abs(dot(worldNormal, lightDir));//gi.light.ndotl;
            //     float shadow = 1.0 * lightHit * ndot * dcof * (0.65 + giInput.ambient * 0.2);// * (1.0 - giInput.ambient);// * pow(.3 / length(occluderWorldPos - worldPos), 0.5);// * max(0, distance - length(occluderWorldPos - worldPos)) / distance;


            //     float ambientHits = 0.0;
            //     float3 dirs = float3(1.0001, 0.0001, 0);
            //     float3 up = normalize(dirs.yxy);
            //     float3 right = normalize(dirs.xyy);
            //     float3 forward = normalize(dirs.yyx);
            //     float3 back = -forward;
            //     float3 left = -right;
            //     float3 down = -up;

            //     for (uint rayIndex = 0; rayIndex < _AoRays; rayIndex++) {
            //         RaymarchInfo aoRay;
            //         INITIALIZE_RAYMARCH_INFO(aoRay, i, 32, 0.001);
            //         aoRay.startPos = worldPos - ray.rayDir * 0.001;
            //         aoRay.rayDir = float3(
            //             _UniformRays[rayIndex * 3 + 0],
            //             _UniformRays[rayIndex * 3 + 1],
            //             _UniformRays[rayIndex * 3 + 2]
            //         );

            //         ambientHits += raycast(aoRay, true) ? pow(max(0.0, 25.0 - aoRay.totalLength) / 25.0, 5.0) / _AoRays : 0.0;
            //     }

            //     float ao = min(1.0, pow(ambientHits, 3.5));
            //     shadow = min(1.0, shadow + ao);

            //     // o.diffuse = lerp(o.diffuse, 0.0, shadow * (1 - o.emission));
            //     // o.emission = lerp(o.emission, 0.0, shadow * (1 - o.emission));
            //     // o.specular = lerp(o.specular, 0.0, shadow * (1 - o.emission));

            //     o.diffuse.rgb  = lerp(o.diffuse.rgb, o.diffuse.rgb * (1.0 - shadow) * giInput.ambient, shadow);
            //     o.emission.rgb  = lerp(o.emission.rgb, o.emission.rgb * (1.0 - shadow) * giInput.ambient, shadow);
            //     o.specular.rgb  = lerp(o.specular.rgb, o.specular.rgb * (1.0 - shadow) * giInput.ambient, shadow);

            //     // o.diffuse.rgb  = o.diffuse.rgb * (1.0 - shadow);
            //     // o.emission.rgb = o.diffuse.rgb * (1.0 - shadow);
            //     // o.specular.rgb = o.diffuse.rgb * (1.0 - shadow);

            //     float debug = ao;// frac(ao);
            //     // float debug = pow(ambientHits / 4.0, 3.0);
            //     // o.diffuse.rgb = o.emission.rgb = aoHit ? aoRay.endPos / _VolumeSize : float3(0,0,0);
            //     // o.diffuse = float4(debug,debug,debug, 0.0);
            //     // o.emission = float4(debug,debug,debug, 0.0);
            //     // o.specular = float4(debug,debug,debug, 1.0);

                return o;
            }
            ENDCG
        }
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster


            float _ShadowExtraBias;
            float _ShadowMinDistance;
            int _ShadowLoop;

            struct appdata 
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
                float4 worldPos  : TEXCOORD1;
                float3 normal    : TEXCOORD2;
                float4 projPos   : TEXCOORD3;
            };

            inline float4 ApplyLinearShadowBias(float4 clipPos)
            {
            #if !(defined(SHADOWS_CUBE) && defined(SHADOWS_CUBE_IN_DEPTH_TEX))
                #if defined(UNITY_REVERSED_Z)
                clipPos.z += max(-1.0, min((unity_LightShadowBias.x - _ShadowExtraBias) / clipPos.w, 0.0));
                #else
                clipPos.z += saturate((unity_LightShadowBias.x + _ShadowExtraBias) / clipPos.w);
                #endif
            #endif

            #if defined(UNITY_REVERSED_Z)
                float clamped = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
            #else
                float clamped = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
            #endif
                clipPos.z = lerp(clipPos.z, clamped, unity_LightShadowBias.y);
                return clipPos;
            }

            v2f Vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                #ifdef DISABLE_VIEW_CULLING
                o.pos.z = 1;
                #endif
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = mul(unity_ObjectToWorld, v.normal);
                o.projPos = ComputeNonStereoScreenPos(o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }


            #if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
            float4 Frag(v2f i) : SV_Target
            {
                RaymarchInfo ray;
                UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
                ray.rayDir = GetCameraDirection(i.projPos);
                ray.startPos = i.worldPos;
                ray.minDistance = _ShadowMinDistance;
                ray.maxDistance = GetCameraFarClip();
                ray.maxLoop = _ShadowLoop;

                bool hit = raycast(ray);

                // float3 rayDir = ray.rayDir;
                // float rayLength = length(rayDir);
                // float3 rayPos = ToLocal(ray.startPos) * _VolumeSize;
                // float3 mapPos = floor(rayPos);
                // float3 deltaDist = abs(float3(rayLength, rayLength, rayLength) / rayDir);
                // float3 rayStep = sign(rayDir);
                // float3 sideDist = (sign(rayDir) * (mapPos - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist; 
                // float3 mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
                // float4 voxel;

                // bool hit = false;
                // for(ray.loop = 0; ray.loop < 85; ray.loop++) {
                //     if (getHit(mapPos, _BufferPtr, voxel)) { 
                //         hit = true; 
                //         break;
                //     }
                    
                //     mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
                //     sideDist += mask * deltaDist;
                //     mapPos += mask * rayStep;
                // }

                if (!hit) {
                    discard;
                }

                // float3 endRayPos = rayDir / dot(mask * rayDir, 1) * dot(mask * (mapPos + step(rayDir, 0) - rayPos), 1) + rayPos;
                // float3 normal = -rayStep * mask;

                // float3 tangent1;
                // float3 tangent2;

                // if (abs(mask.x) > 0.) {
                //     // uv = endRayPos.yz;
                //     tangent1 = float3(0,1,0);
                //     tangent2 = float3(0,0,1);
                // }
                // else if (abs(mask.y) > 0.) {
                //     // uv = endRayPos.xz;
                //     tangent1 = float3(1,0,0);
                //     tangent2 = float3(0,0,1);
                // }
                // else {
                //     // uv = endRayPos.xy;
                //     tangent1 = float3(1,0,0);
                //     tangent2 = float3(0,1,0);
                // }

                float3 worldPos = ToWorld(ray.endPos / _VolumeSize);
                float3 worldNormal = ray.normal;// 2.0 * normal - 1.0;
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));


                i.vec = worldPos - _LightPositionRange.xyz;
                SHADOW_CASTER_FRAGMENT(i);
            }
            #else

            void Frag(
                v2f i, 
                out float4 outColor : SV_Target, 
                out float  outDepth : SV_Depth)
            {
                RaymarchInfo ray;
                UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
                ray.startPos = i.worldPos;
                ray.minDistance = _ShadowMinDistance;
                ray.maxDistance = GetCameraFarClip();
                ray.maxLoop = _ShadowLoop;

                if (IsCameraPerspective()) {
                    // Hack: This pass run in the UpdateDepthTexture stage.
                    if (abs(unity_LightShadowBias.x) < 1e-5) {
                        ray.rayDir = normalize(i.worldPos - GetCameraPosition());
            #ifdef CAMERA_INSIDE_OBJECT
                        float3 startPos = GetCameraPosition() + GetDistanceFromCameraToNearClipPlane(i.projPos) * ray.rayDir;
                        if (IsInnerObject(startPos)) {
                            ray.startPos = startPos;
                            ray.polyNormal = -ray.rayDir;
                        }
            #endif
                    // Run in the SpotLight shadow stage.
                    } else {
                        ray.rayDir = GetCameraDirection(i.projPos);
                    }
                } else {
                    ray.rayDir = GetCameraForward();
                }

                // float3 rayDir = ray.rayDir;
                // float rayLength = length(rayDir);
                // float3 rayPos = ToLocal(ray.startPos) * _VolumeSize;
                // float3 mapPos = floor(rayPos);
                // float3 deltaDist = abs(float3(rayLength, rayLength, rayLength) / rayDir);
                // float3 rayStep = sign(rayDir);
                // float3 sideDist = (sign(rayDir) * (mapPos - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist; 
                // float3 mask;
                // float4 voxel;

                // bool hit = false;
                // for(ray.loop = 0; ray.loop < 85; ray.loop++) {
                //     if (getHit(mapPos, _BufferPtr, voxel)) { 
                //         hit = true; 
                //         break;
                //     }
                    
                //     mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
                //     sideDist += mask * deltaDist;
                //     mapPos += mask * rayStep;
                // }

                // if (!hit) {
                //     discard;
                // }

                // float3 endRayPos = rayDir / dot(mask * rayDir, 1) * dot(mask * (mapPos + step(rayDir, 0) - rayPos), 1) + rayPos;
                // float3 normal = -rayStep * mask;

                // float3 tangent1;
                // float3 tangent2;

                // if (abs(mask.x) > 0.) {
                //     // uv = endRayPos.yz;
                //     tangent1 = float3(0,1,0);
                //     tangent2 = float3(0,0,1);
                // }
                // else if (abs(mask.y) > 0.) {
                //     // uv = endRayPos.xz;
                //     tangent1 = float3(1,0,0);
                //     tangent2 = float3(0,0,1);
                // }
                // else {
                //     // uv = endRayPos.xy;
                //     tangent1 = float3(1,0,0);
                //     tangent2 = float3(0,1,0);
                // }

                if (!raycast(ray)) {
                    discard;
                }

                float3 worldPos = ToWorld(ray.endPos / _VolumeSize);
                float3 worldNormal = ray.normal;// 2.0 * normal - 1.0;
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                float4 opos = mul(unity_WorldToObject, float4(worldPos, 1.0));
                opos = UnityClipSpaceShadowCasterPos(opos, worldNormal);
                opos = ApplyLinearShadowBias(opos);
                outColor = outDepth = EncodeDepth(opos);
            }

            #endif

            ENDCG
        }
    }
}
