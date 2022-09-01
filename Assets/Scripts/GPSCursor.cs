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
