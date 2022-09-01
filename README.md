# TestSimulation_UnityProject par Cyril Ghys

mail : cyril.ghys@gmail.com

Test réalisé en 4h30. Toutes les étapes ont été complétées.

Vous pouvez retrouver le code écrit, et des remarques les accompagnant, ci-dessous.

![alt text](https://github.com/ghysc/TestSimulation_UnityProject/blob/main/earth.png "Capture d'écran application")

## GPSCursor.cs

Pour ce 1er exercice, j'ai rapidement obtenu de 1ers résultats. Je savais qu'il fallait utiliser des fonctions trigonométriques pour obtenir le résultat voulu. Toutefois, avant d'obtenir les coordonées 3D pour la sphère, je suis passé par un cylindre et un octahèdre.

Le GUI n'a posé de problème quant à lui. Il est resté simple.

```c#
using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class GPSCursor : MonoBehaviour
{
    [Range(-90f, 90f)]
    [Tooltip("Latitude goes from -90° to 90° ; when below zero, latitude is in South hemisphere ; when above, it's in the North hemisphere")]
    public float latitude;
    [Range(-180f, 180f)]
    [Tooltip("Longitude goes from -180° to 180° ; when below zero, longitude goes to West ; when above, it goes to East")]
    public float longitude;
    public float altitude;

    private Transform _earthPivot;
    private float _earthRadius;

    private void Start()
    {
        _earthPivot = transform.parent.parent;
        // assuming earth radius is baked in pivot scale, as from the original project
        // earth radius shouldn't change at runtime so it shall be safe to retrieve it only once in Start
        _earthRadius = _earthPivot.localScale.x * .5f;
    }

    private void Update() => UpdateCursorPosition();

    private void OnValidate()
    {
        _earthPivot = transform.parent.parent;
        // assuming earth radius is baked in pivot scale, as from the original project
        _earthRadius = _earthPivot.localScale.x * .5f;

        UpdateCursorPosition();
    }

    private void UpdateCursorPosition()
    {
        if (altitude < -_earthRadius)
        {
            Debug.LogWarning("Beware, altitude cannot be less than earth radius");
            altitude = -_earthRadius;
        }

        Vector3 pos = _earthPivot.position;
        Vector3 direction = Vector3.zero;

        float radLatitude = latitude * Mathf.Deg2Rad;
        float radLongitude = longitude * Mathf.Deg2Rad;
        direction.x = Mathf.Cos(radLongitude) * Mathf.Cos(radLatitude);
        direction.y = Mathf.Sin(radLatitude);
        direction.z = Mathf.Sin(radLongitude) * Mathf.Cos(radLatitude);

        pos += direction * _earthRadius + direction * altitude;

        transform.position = pos;
    }

    private void OnGUI()
    {
        GUILayout.BeginVertical("box", GUILayout.Width(300));

        GUIStyle title = new GUIStyle("label");
        title.fontSize = 24;
        title.alignment = TextAnchor.MiddleCenter;
        GUILayout.Label("Latitude & Longitude", title);

        GUILayout.Space(20);

        GUIStyle core = new GUIStyle("label");
        core.fontSize = 16;
        core.alignment = TextAnchor.MiddleCenter;
        latitude = GUILayout.HorizontalSlider(latitude, -90f, 90f);
        char hemisphere = Mathf.Sign(latitude) >= 0 ? 'N' : 'S';
        string strLat = string.Format("Latitude: {0:00.0000000}° " + hemisphere, Mathf.Abs(latitude));
        GUILayout.Label("" + strLat, core);

        GUILayout.Space(10);

        longitude = GUILayout.HorizontalSlider(longitude, -180f, 180f);
        char side = Mathf.Sign(longitude) >= 0 ? 'E' : 'O';
        string strLon = string.Format("Longitude: {0:00.0000000}° " + side, Mathf.Abs(longitude));
        GUILayout.Label("" + strLon, core);

        GUILayout.Space(10);

        if (GUILayout.Button("Reset"))
        {
            latitude = 0f;
            longitude = 0f;
        }

        GUILayout.EndVertical();
    }
}
```

## OceanMaskLinker.cs

Ici, j'utilise la méthode Shader.PropertyToID pour avoir un résultat optimisé. 

Autrement, je prends en compte différentes erreurs possibles (mauvais nom de fichier, fichier inexsitant, pas de Material renseigné et mauvais nom d'attribut de shader renseigné).

```c#
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class OceanMaskLinker : MonoBehaviour
{
    public string pngName = "water_mask.png";
    public Material earthMaterial;

    private static readonly int OCEAN_MASK_ID = Shader.PropertyToID("_OceanMask");

    private void Start()
    {
        if (earthMaterial == null)
        {
            Debug.LogError("Please specify a material in " + this);
            return;
        }

        string path = Application.streamingAssetsPath + "/" + pngName;
        if (!File.Exists(path))
        {
            Debug.LogError("Wrong name specified in " + this + ", or files does not exist");
            return;
        }

        byte[] fileContent = File.ReadAllBytes(path);
        Texture2D tex = new Texture2D(2, 2, TextureFormat.ARGB32, false);
        tex.LoadImage(fileContent);

        if (earthMaterial.HasTexture(OCEAN_MASK_ID))
            earthMaterial.SetTexture(OCEAN_MASK_ID, tex);
        else
            Debug.LogError(earthMaterial + " has no texture called _OceanMask");
    }
}
```

## FramerateManager.cs

Pas grand chose à signaler ici.

```c#
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FramerateManager : MonoBehaviour
{
    public int framerate = 30;

    private void Start() => Application.targetFrameRate = framerate;
}
```

## EarthShader.shader

Ici, plusieurs choses : 

J'ai bien spécifié le type de texure en tant que Normal Map (gentil comme piège !) et j'en ai profité pour rajouter le tag [Normal] dans la section Properties. 

Ensuite, dans la structure v2f, j'ai changé le type de uv de float2 à float4 pour pouvoir stocker les UVs transformés (tiling & offset) dans .xy, et les UVs non transformés dans .zw : c'est utile dans la mesure où la normal map prend en compte les 2 premiers canaux (=> possibilité de jouer avec les reflets), et où le ocean mask prend en compte les 2 derniers (=> on a pas envie que cette texture soit tilée ni offsetée). 

Enfin, concernant les calculs d'éclairage, j'ai fait quelques va-et-vient pour trouver la bonne formule, pour se rapprocher au mieux du résultat affiché dans le PDF. J'ai fini par laisser les 2 manières de faire par lesquelles j'avais commencé (Phong et Blinn-Phong), et en proposer une 3ème, qui prend en compte à la fois la normal map et la world normal.

Le masque d'ocean est ensuité appliqué dans le compositing de la couleur spéculaire.

```shaderlab
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
```
