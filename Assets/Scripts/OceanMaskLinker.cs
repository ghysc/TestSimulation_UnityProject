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
