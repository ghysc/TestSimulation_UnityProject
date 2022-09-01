Shader "Test/EarthShader"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_BaseMap("Earth Map", CUBE) = "white" {}

		[Normal] _NormalMap("Normal Map", 2D) = "white" {}

		_OceanMask("Ocean Mask", 2D) = "white" {}

		// Ambient light is applied uniformly to all surfaces on the object.
		[HDR]
		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)
		[HDR]
		_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
		// Controls the size of the specular reflection.
		_Glossiness("Glossiness", Float) = 3
	}

	SubShader
	{
		Pass
		{
			// Setup our pass to use Forward rendering, and only receive
			// data on the main directional light and ambient light.
			Tags
			{
				"LightMode" = "ForwardBase"
				"PassFlags" = "OnlyDirectional"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// Compile multiple versions of this shader depending on lighting settings.
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			// Files below include macros and functions to assist
			// with lighting and shadows.
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				// here I swapped uv from float2 to float4 - xy for transformed uv (tiling & offset), and zw non-transformed one
				float4 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
				// Macro found in Autolight.cginc. Declares a vector4
				// into the TEXCOORD2 semantic with varying precision 
				// depending on platform target.
				SHADOW_COORDS(2)

				float3 normalWorld: TEXCOORD3;
				float3 tangentWorld: TEXCOORD4;
				float3 binormalWorld: TEXCOORD5;
			};

			samplerCUBE _BaseMap;
			float4 _BaseMap_ST;

			sampler2D _NormalMap;
			float4 _NormalMap_ST;

			sampler2D _OceanMask;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.viewDir = WorldSpaceViewDir(v.vertex);
				o.normal = v.normal;
				o.uv.xy = TRANSFORM_TEX(v.uv.xy, _BaseMap);
				o.uv.zw = v.uv.xy;
				// Defined in Autolight.cginc. Assigns the above shadow coordinate
				// by transforming the vertex from world space to shadow-map space.

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				o.tangentWorld = normalize(
					mul(modelMatrix, float4(v.tangent.xyz, 0.0)).xyz);
				o.normalWorld = normalize(
					mul(float4(v.normal, 0.0), modelMatrixInverse).xyz);
				o.binormalWorld = normalize(
					cross(o.normalWorld, o.tangentWorld)
					* v.tangent.w); // tangent.w is specific to Unity

				TRANSFER_SHADOW(o)
				return o;
			}

			float4 _Color;
			float4 _AmbientColor;
			float4 _SpecularColor;
			float _Glossiness;
			half4 _SeaColor;


			float4 frag(v2f i) : SV_Target
			{
				half4 base = texCUBE(_BaseMap, i.normal * float3(-1, 1, 1));

				float3 normal = i.normalWorld;

				float3 viewDir = normalize(i.viewDir);

				// Calculate illumination from directional light.
				// _WorldSpaceLightPos0 is a vector pointing the OPPOSITE
				// direction of the main directional light.
				float NdotL = saturate(dot(_WorldSpaceLightPos0, normal));

				// Samples the shadow map, returning a value in the 0...1 range,
				// where 0 is in the shadow, and 1 is not.
				float shadow = SHADOW_ATTENUATION(i);
				// Partition the intensity into light and dark, smoothly interpolated
				// between the two to avoid a jagged break.
				float lightIntensity = NdotL * shadow;

				// Multiply by the main directional light's intensity and color.
				float4 light = lightIntensity * _LightColor0;

				// Get a moving normal map 
				float2 uv1 = i.uv.xy + _Time * float2(.2, -.01);
				half3 normalMap1 = UnpackNormal(tex2D(_NormalMap, uv1));
				float2 uv2 = i.uv.xy + _Time * float2(-.2, .01);
				half3 normalMap2 = UnpackNormal(tex2D(_NormalMap, uv2));
				half3 normalMap = (normalMap1 + normalMap2) * .5;

				// Calculate specular reflection
				float spec = 0.;
				if (false)
				{
					// Phong
					half3 reflectDir = reflect(-_WorldSpaceLightPos0, normalMap);
					spec = pow(max(dot(reflectDir, viewDir), 0), _Glossiness);
				}
				else if (false)
				{
					// Blinn-Phong
					half3 halfwayDir = normalize(_WorldSpaceLightPos0 + viewDir);
					spec = pow(max(dot(normalMap, halfwayDir), 0), _Glossiness);
				}
				else 
				{
					// My guess
					half3 halfwayDir = normalize(_WorldSpaceLightPos0 + viewDir);
					float glossArea = pow(max(dot(normal, halfwayDir), 0), _Glossiness);
					spec = max(dot(normalMap, halfwayDir), 0) * glossArea;
				}

				float oceanMask = tex2D(_OceanMask, i.uv.zw).r;
				float4 specular = _SpecularColor * spec * _SpecularColor.a * oceanMask;

				return (light + _AmbientColor) * base + specular;
			}
			ENDCG
		}

		// Shadow casting support.
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
